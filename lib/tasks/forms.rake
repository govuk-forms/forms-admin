# frozen_string_literal: true

namespace :forms do
  desc "move one or more forms into group"
  task :move, [] => :environment do |_, args|
    *form_ids, group_id = args.to_a

    usage_message = "usage: rake forms:move[<form_id>, ..., <group_id>]"
    abort usage_message if form_ids.blank? || group_id.blank?

    ActiveRecord::Base.transaction do
      move_forms(form_ids, group_id)
    end
  end

  desc "move one or more forms into group"
  task :move_dry_run, [] => :environment do |_, args|
    *form_ids, group_id = args.to_a

    usage_message = "usage: rake forms:move_dry_run[<form_id>, ..., <group_id>]"
    abort usage_message if form_ids.blank? || group_id.blank?

    ActiveRecord::Base.transaction do
      move_forms(form_ids, group_id)
      Rails.logger.info "forms:move_dry_run rollback"
      raise ActiveRecord::Rollback
    end
  end

  desc "set the state for a form by transitioning through the form state machine"
  task :set_state, %i[form_id state] => :environment do |_, args|
    usage_message = "usage: rake forms:set_state[<form_id>, <state>]"
    abort usage_message if args[:form_id].blank? || args[:state].blank?
    abort "state must be one of #{Form.states.keys.join(', ')}" unless Form.states.key?(args[:state])

    form = Form.find(args[:form_id])

    # the make_live event guard checks the form's task statuses through a
    # service that is normally injected by the controller
    form.set_task_status_service(TaskStatusService.new(form:))

    events = Form.event_path(from: form.aasm.current_state, to: args[:state].to_sym)

    abort "cannot transition form from \'#{form.state}\' to \'#{args[:state]}\'" if events.nil?

    if events.empty?
      Rails.logger.info "forms:set_state: #{fmt_form(form)} is already in state \'#{form.state}\'"
      next
    end

    ActiveRecord::Base.transaction do
      events.each do |event|
        Rails.logger.info "forms:set_state: firing #{event} on #{fmt_form(form)} in state \'#{form.state}\'"
        form.public_send(:"#{event}!")
      end
    end
  end

  namespace :submission_email do
    desc "set the submission email for a form, without validation"
    task :update, %i[form_id submission_email] => :environment do |_, args|
      usage_message = "usage: rake forms:submission_email:update[<form_id>, <submission_email>]"
      abort usage_message if args[:form_id].blank? || args[:submission_email].blank?
      raise "'#{args[:submission_email]}' is not an email address" unless args[:submission_email].match?(/.*@.*/)

      form = Form.find(args[:form_id])
      form.submission_email = args[:submission_email]

      Rails.logger.info "forms:submission_email:update: setting #{fmt_form(form)} submission email to \'#{form.submission_email}\'"

      # skip validations on the Form model, don't update live or archived
      form.save!(validate: false)

      form.form_submission_email&.destroy!
    end
  end

  namespace :delivery_configurations do
    desc "Enable email delivery for submissions"
    task :enable_email, %i[form_id] => :environment do |_, args|
      usage_message = "usage: rake forms:delivery_configurations:enable_email[<form_id>]"
      abort usage_message if args[:form_id].blank?

      form = Form.find(args[:form_id])
      delivery_configuration = form.delivery_configurations.find_or_initialize_by(delivery_method: :email, delivery_schedule: :immediate)
      delivery_configuration.save!

      # ensure draft form document is updated
      form.delivery_configurations.reload
      form.save!

      if form.is_live?
        form.form_documents.where(tag: "live").find_each do |form_document|
          delivery_configurations = form_document["content"]["delivery_configurations"]
          has_email_delivery = delivery_configurations.any? { |d| d["delivery_method"] == "email" && d["delivery_schedule"] == "immediate" }

          unless has_email_delivery
            delivery_configurations << DeliveryConfiguration.new(form: form, delivery_method: "email", delivery_schedule: "immediate")
          end
          form_document.save!
        end
      end

      Rails.logger.info "Enabled email delivery for #{fmt_form(form)}"
    end

    desc "Disable email delivery for submissions"
    task :disable_email, %i[form_id] => :environment do |_, args|
      usage_message = "usage: rake forms:delivery_configurations:disable_email[<form_id>]"
      abort usage_message if args[:form_id].blank?

      form = Form.find(args[:form_id])
      abort "Email delivery is not enabled" if form.immediate_email_delivery_configuration.nil?
      abort "Form will have no delivery methods, enable S3 delivery first" if form.delivery_configurations.immediate.one?

      form.delivery_configurations.where(delivery_method: :email, delivery_schedule: :immediate).destroy_all

      # ensure draft form document is updated
      form.delivery_configurations.reload
      form.save!

      if form.is_live?
        form.form_documents.where(tag: "live").find_each do |form_document|
          delivery_configurations = form_document["content"]["delivery_configurations"]
          delivery_configurations.reject! { |d| d["delivery_method"] == "email" && d["delivery_schedule"] == "immediate" }
          form_document.save!
        end
      end

      Rails.logger.info "Disabled email delivery for #{fmt_form(form)}"
    end

    desc "Disable S3 delivery for submissions"
    task :disable_s3, %i[form_id] => :environment do |_, args|
      usage_message = "usage: rake forms:delivery_configurations:disable_s3[<form_id>]"
      abort usage_message if args[:form_id].blank?

      form = Form.find(args[:form_id])
      abort "S3 delivery is not enabled" if form.s3_delivery_configuration.nil?
      abort "Form will have no delivery methods, enable email delivery first" if form.delivery_configurations.immediate.one?

      form.s3_bucket_name = nil
      form.s3_bucket_aws_account_id = nil
      form.s3_bucket_region = nil
      form.delivery_configurations.where(delivery_method: :s3, delivery_schedule: :immediate).destroy_all

      # ensure draft form document is updated
      form.delivery_configurations.reload
      form.save!

      if form.is_live?
        form.form_documents.where(tag: "live").find_each do |form_document|
          content = form_document.content

          content["s3_bucket_name"] = nil
          content["s3_bucket_aws_account_id"] = nil
          content["s3_bucket_region"] = nil

          delivery_configurations = content["delivery_configurations"]
          delivery_configurations.reject! { |d| d["delivery_method"] == "s3" && d["delivery_schedule"] == "immediate" }

          form_document.save!
        end
      end

      Rails.logger.info "Disabled s3 delivery for #{fmt_form(form)}"
    end

    desc "Enable S3 delivery for submissions"
    task :enable_s3, %i[form_id s3_bucket_name s3_bucket_aws_account_id s3_bucket_region format disable_email] => :environment do |_, args|
      usage_message = "usage: rake forms:delivery_configurations:enable_s3[<form_id>, <s3_bucket_name>, <s3_bucket_aws_account_id>, <s3_bucket_region>, <format>, <disable_email>]"
      abort usage_message if args[:form_id].blank?
      abort usage_message if args[:s3_bucket_name].blank?
      abort usage_message if args[:s3_bucket_aws_account_id].blank?
      abort usage_message if args[:s3_bucket_region].blank?
      abort usage_message if args[:format].blank?
      abort usage_message if args[:disable_email].blank? || !args[:disable_email].in?(%w[true false])
      abort "s3_bucket_region must be one of eu-west-1 or eu-west-2" unless %w[eu-west-1 eu-west-2].include? args[:s3_bucket_region]
      abort "format must be one of csv or json" unless %w[csv json].include? args[:format]

      formats = [args[:format]]
      disable_email = args[:disable_email] == "true"

      Rails.logger.info("Enabling s3 submissions with s3_bucket_name #{args[:s3_bucket_name]} for form: #{args[:form_id]}")
      form = Form.find(args[:form_id])
      form.s3_bucket_name = args[:s3_bucket_name]
      form.s3_bucket_aws_account_id = args[:s3_bucket_aws_account_id]
      form.s3_bucket_region = args[:s3_bucket_region]

      delivery_configuration = form.delivery_configurations.find_or_initialize_by(delivery_method: :s3, delivery_schedule: :immediate)
      delivery_configuration.formats = formats
      delivery_configuration.save!

      if disable_email
        form.delivery_configurations.where(delivery_method: :email, delivery_schedule: :immediate).destroy_all
      end

      form.save!

      if form.is_live?
        form.form_documents.where(tag: "live").find_each do |form_document|
          content = form_document.content

          content["s3_bucket_name"] = args[:s3_bucket_name]
          content["s3_bucket_aws_account_id"] = args[:s3_bucket_aws_account_id]
          content["s3_bucket_region"] = args[:s3_bucket_region]

          delivery_configurations = content["delivery_configurations"]
          existing_s3_configuration = delivery_configurations.find { |d| d["delivery_method"] == "s3" && d["delivery_schedule"] == "immediate" }

          if existing_s3_configuration.present?
            existing_s3_configuration["formats"] = formats
          else
            delivery_configurations << DeliveryConfiguration.new(form: form, delivery_method: "s3", delivery_schedule: "immediate", formats: formats)
          end

          if disable_email
            delivery_configurations.reject! { |d| d["delivery_method"] == "email" && d["delivery_schedule"] == "immediate" }
          end

          form_document.save!
        end
      end

      if disable_email
        Rails.logger.info("Enabled s3 submissions to bucket #{args[:s3_bucket_name]} and disabled email submissions for form: #{args[:form_id]}")
      else
        Rails.logger.info("Enabled s3 submissions to bucket #{args[:s3_bucket_name]} for form: #{args[:form_id]}. Email submissions are still enabled.")
      end
    end
  end

  desc "List all forms that are not in a group"
  task list_forms_without_group: :environment do
    forms = Form.where.missing(:group_form)

    Rails.logger.info "Found #{forms.count} forms without a group"
    forms.find_each do |form|
      creator = User.find(form.creator_id) if form.creator_id.present?
      Rails.logger.info "Form #{form.id} (\"#{form.name}\") created by #{creator&.name || 'No creator'} with organisation #{creator&.organisation&.name || 'N/A'}"
    end
  end

  desc "Add exit page objects for all existing exit pages"
  task sync_all_exit_pages: :environment do
    Rails.logger.info "Starting with #{ExitPage.count} exit page objects"

    Condition.find_each do |condition|
      if condition.is_exit_page? && condition.exit_page.nil?
        condition.sync_exit_page
        condition.save!
      end
    end

    Rails.logger.info "Finished with #{ExitPage.count} exit page objects"
  end

  desc "Show how the exit pages for a form are stored in the database, as JSON"
  task :show_exit_pages, %i[form_id] => :environment do |_, args|
    usage_message = "usage: rake forms:show_exit_pages[<form_id>]"
    abort usage_message if args[:form_id].blank?

    form = Form.find(args[:form_id])

    pages = form.pages
      .includes(routing_conditions: [:translations, { exit_page: :translations }], exit_pages: %i[translations conditions])
      .order(:position)
      .select { it.routing_conditions.any? || it.exit_pages.any? }
      .map { exit_pages_for_page(it) }

    conditions = pages.flat_map { it[:routing_conditions] }
    exit_pages = pages.flat_map { it[:exit_pages] }

    puts JSON.pretty_generate(
      form: { id: form.id, name: form.name, state: form.state },
      summary: {
        routing_conditions: conditions.count,
        # how many conditions are stored in each way, see exit_page_representation
        representations: conditions.map { it[:representation] }.tally,
        exit_pages: exit_pages.count,
        exit_pages_without_conditions: exit_pages.count { it[:condition_ids].empty? },
      },
      pages:,
      form_documents: form.form_documents.order(:id).map { exit_pages_for_form_document(it) },
    )
  end

  desc "List the contact emails for the given form IDs"
  task :list_contact_emails, [] => :environment do |_, args|
    form_ids = args.to_a
    usage_message = "usage: rake forms:list_contact_emails[<form_id>, ...]"
    abort usage_message if form_ids.blank?

    form_ids.each do |form_id|
      form = Form.find(form_id)
      creator_email = User.where(id: form.creator_id).pick(:email) if form.creator_id.present?
      group = form.group

      group_admins = group.users.group_admins.pluck(:email)
      organisation = group.organisation
      org_admins = organisation.admin_users.pluck(:email)

      puts "Form ID: #{form_id}, Form Name: #{form.name}, Organisation: #{organisation.name}, Group: #{group.name}"
      puts "Form creator: #{creator_email || 'Unknown'}"
      puts "Group admins: #{group_admins.join(', ')}"
      puts "Organisation admins: #{org_admins.join(', ')}\n"
    end
  end
end

def move_forms(form_ids, group_id)
  group = Group.find_by! external_id: group_id

  form_ids.each do |form_id|
    form = Form.find(form_id)
    group_form = GroupForm.find_or_initialize_by(form_id:)

    if group_form.group == group
      Rails.logger.info "forms:move: keeping #{fmt_form(form)} in #{fmt_group(group)}"
      next
    elsif group_form.persisted?
      Rails.logger.info "forms:move: moving #{fmt_form(form)} from #{fmt_group(group_form.group)} to #{fmt_group(group)}"
    else
      Rails.logger.info "forms:move: adding #{fmt_form(form)} to #{fmt_group(group)}"
    end

    group_form.update!(group:)
  end
end

def fmt_form(form)
  "form #{form.id} (\"#{form.name}\")"
end

def exit_pages_for_page(page)
  {
    id: page.id,
    external_id: page.external_id,
    position: page.position,
    question_text: page.question_text,
    routing_conditions: page.routing_conditions.sort_by(&:id).map { exit_pages_for_condition(it) },
    exit_pages: page.exit_pages.sort_by(&:id).map do |exit_page|
      exit_page_record(exit_page).merge(condition_ids: exit_page.conditions.map(&:id).sort)
    end,
  }
end

def exit_pages_for_condition(condition)
  # Condition#exit_page_heading and #exit_page_markdown return the values from
  # the ExitPage when there is one, so read the columns directly to see what is
  # stored on the condition itself
  legacy = stored_translations(condition, heading: :exit_page_heading, markdown: :exit_page_markdown)
  exit_page = condition.exit_page && stored_translations(condition.exit_page, heading: :heading, markdown: :markdown)
  differences = exit_page ? legacy.keys.reject { legacy[it] == exit_page[it] } : []

  {
    id: condition.id,
    answer_value: condition.answer_value,
    check_page_id: condition.check_page_id,
    goto_page_id: condition.goto_page_id,
    skip_to_end: condition.skip_to_end,
    updated_at: condition.updated_at,
    representation: exit_page_representation(condition, legacy, differences),
    differences:,
    legacy_exit_page_fields: legacy,
    exit_page_id: condition.exit_page_id,
    exit_page: condition.exit_page && exit_page_record(condition.exit_page),
  }
end

def exit_page_representation(condition, legacy, differences)
  has_legacy_fields = legacy.values.any?(&:present?)

  if condition.exit_page.nil?
    has_legacy_fields ? "legacy_fields_only" : "not_an_exit_page"
  elsif !has_legacy_fields
    "exit_page_model_only"
  else
    differences.empty? ? "both_in_sync" : "both_out_of_sync"
  end
end

def exit_page_record(exit_page)
  {
    id: exit_page.id,
    question_page_id: exit_page.question_page_id,
    created_at: exit_page.created_at,
    updated_at: exit_page.updated_at,
    **stored_translations(exit_page, heading: :heading, markdown: :markdown),
  }
end

# English values are stored in the record's own table, other languages are
# stored in its translations table
def stored_translations(record, heading:, markdown:)
  welsh = record.translations.find { it.locale == "cy" }

  {
    heading: record.read_attribute(heading),
    markdown: record.read_attribute(markdown),
    heading_cy: welsh&.read_attribute(heading),
    markdown_cy: welsh&.read_attribute(markdown),
  }
end

def exit_pages_for_form_document(form_document)
  steps = form_document.content["steps"] || []

  {
    id: form_document.id,
    tag: form_document.tag,
    version: form_document.version,
    language: form_document.language,
    updated_at: form_document.updated_at,
    steps: steps.filter_map do |step|
      routing_conditions = step["routing_conditions"] || []
      exit_pages = step["exit_pages"] || []
      next if routing_conditions.empty? && exit_pages.empty?

      {
        id: step["id"],
        position: step["position"],
        routing_conditions: routing_conditions.map { it.slice("id", "answer_value", "goto_page_id", "skip_to_end", "exit_page_id", "exit_page_heading", "exit_page_markdown") },
        exit_pages:,
      }
    end,
  }
end

def fmt_group(group)
  "group #{group.external_id} (\"#{group.name}\", #{group.organisation.name}, #{group.creator&.name || 'GOV.UK Forms Team'})"
end

def validate_email(email)
  NotificationsUtils::RecipientValidation::EmailAddress.validate_email_address(email)
  true
rescue NotificationsUtils::RecipientValidation::InvalidEmailError
  false
end
