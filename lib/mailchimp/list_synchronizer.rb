require "digest"
require "MailchimpMarketing"

class Mailchimp::ListSynchronizer
  attr_reader :client, :list_id

  PAGE_SIZE = 1000

  def initialize(list_id:)
    @list_id = list_id
    @client = setup_client(Settings.mailchimp.api_key, Settings.mailchimp.api_prefix)
  end

  def setup_client(api_key, server)
    MailchimpMarketing::Client.new.tap do |client|
      client.set_config(
        api_key: api_key,
        server: server,
      )
    end
  end

  def synchronize(desired_members:)
    desired_members_hash = desired_members.index_by(&:subscriber_hash)
    existing_members_hash = fetch_all_members.index_by(&:subscriber_hash)

    add_and_update_members(existing_members_hash, desired_members_hash)
    archive_removed_members(existing_members_hash, desired_members_hash)
  end

  def add_and_update_members(existing_members, desired_members)
    Rails.logger.debug "Subscribing any new users..."
    members_to_update = []

    desired_members.each do |subscriber_hash, desired_member|
      existing_member = existing_members[subscriber_hash]

      next if existing_member&.unsubscribed?
      next if existing_member == desired_member

      members_to_update << desired_member
    end

    Rails.logger.debug "There are #{members_to_update.count} to subscribe"

    members_to_update.each do |member|
      update_member(member)
    end
  end

  def archive_removed_members(existing_members, desired_members)
    Rails.logger.debug "Archiving any removed users..."
    members_to_remove = []

    existing_members.each do |subscriber_hash, existing_member|
      if !desired_members[subscriber_hash] && existing_member.archivable?
        members_to_remove << existing_member
      end
    end

    Rails.logger.debug "There are #{members_to_remove.size} to archive"

    members_to_remove.each do |member|
      remove_member(member)
    end
  end

  def fetch_all_members
    return enum_for(:fetch_all_members) unless block_given?

    offset = 0
    mailchimp_list = client.lists.get_list(list_id, include_total_contacts: true)
    total_size = mailchimp_list["stats"]["total_contacts"]

    Rails.logger.debug "Found Mailchimp list: #{mailchimp_list['name']}"
    Rails.logger.debug "Mailchimp list has #{mailchimp_list['stats']['member_count']} active members"
    Rails.logger.debug "Mailchimp list has #{mailchimp_list['stats']['total_contacts']} total members"

    while offset < total_size
      response = client.lists.get_list_members_info(list_id, count: PAGE_SIZE, offset: offset)

      response["members"].each do |member_data|
        yield Mailchimp::Member.new(
          email: member_data["email_address"],
          status: member_data["status"],
          role: member_data.dig("merge_fields", "ROLE"),
        )
      end

      offset += PAGE_SIZE
    end
  end

  def update_member(member)
    member_data = {
      "email_address" => member.email,
      "status" => member.status,
    }

    member_data["merge_fields"] = { "ROLE" => member.role } if member.role

    client.lists.set_list_member(
      list_id,
      member.subscriber_hash,
      member_data,
    )

    update_member_tags(member)
  rescue MailchimpMarketing::ApiError => e
    log_mailchimp_error("subscribe", member.subscriber_hash, e)
  end

  def update_member_tags(member)
    return if member.tags.empty?

    client.lists.update_list_member_tags(
      list_id,
      member.subscriber_hash,
      { "tags" => member.tags },
    )
  rescue MailchimpMarketing::ApiError => e
    log_mailchimp_error("tag", member.subscriber_hash, e)
  end

  def remove_member(member)
    client.lists.delete_list_member(list_id, member.subscriber_hash)
  rescue MailchimpMarketing::ApiError => e
    log_mailchimp_error("archive", member.subscriber_hash, e)
  end

  def log_mailchimp_error(action, subscriber_hash, error)
    error_details = {}

    response_body = error.instance_variable_get("@response_body")

    begin
      if response_body
        parsed_body = JSON.parse(response_body)
        error_details = parsed_body.is_a?(Hash) ? parsed_body : {}
      end
    rescue JSON::ParserError
      error_details = {}
    end

    error_details["title"] ||= "Unknown error"
    error_details["status"] ||= error.respond_to?(:status) ? error.status : "Unknown status"
    error_details["detail"] ||= "Unparseable or empty response_body"
    error_details["instance"] ||= "unknown"

    EmailParameterFilterProc.new.call(nil, error_details["detail"].to_s)

    Rails.logger.warn(
      task: "Mailchimp::ListSynchronizer#synchronize",
      mailchimp_action: action,
      subscriber_hash: subscriber_hash,
      title: error_details["title"],
      detail: error_details["detail"],
      status: error_details["status"],
      instance: error_details["instance"],
    )
  end
end
