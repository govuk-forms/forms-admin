namespace :forms do
  desc "move one or more forms into group"
  task :move, [] => :environment do |_, args|
    *form_ids, group_id = args.to_a

    usage_message = "usage: rake forms:move[<form_id>, ..., <group_id>]".freeze
    abort usage_message if form_ids.blank? || group_id.blank?

    ActiveRecord::Base.transaction do
      move_forms(form_ids, group_id)
    end
  end

  desc "move one or more forms into group"
  task :move_dry_run, [] => :environment do |_, args|
    *form_ids, group_id = args.to_a

    usage_message = "usage: rake forms:move_dry_run[<form_id>, ..., <group_id>]".freeze
    abort usage_message if form_ids.blank? || group_id.blank?

    ActiveRecord::Base.transaction do
      move_forms(form_ids, group_id)
      Rails.logger.info "forms:move_dry_run rollback"
      raise ActiveRecord::Rollback
    end
  end

  desc "set the state for a form by transitioning through the form state machine"
  task :set_state, %i[form_id state] => :environment do |_, args|
    usage_message = "usage: rake forms:set_state[<form_id>, <state>]".freeze
    abort usage_message if args[:form_id].blank? || args[:state].blank?
    abort "state must be one of #{Form.states.keys.join(', ')}" unless Form.states.key?(args[:state])

    form = Form.find(args[:form_id])

    # the make_live event guard checks the form's task statuses through a
    # service that is normally injected by the controller
    form.set_task_status_service(TaskStatusService.new(form:, current_user: nil))

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
      usage_message = "usage: rake forms:submission_email:update[<form_id>, <submission_email>]".freeze
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

  namespace :submission_type do
    desc "Set submission_type to email"
    task :set_to_email, %i[form_id submission_formats] => :environment do |_, args|
      submission_format = args[:submission_formats].nil? ? [] : args.to_a[1..]
      submission_format = [] if submission_format == %w[email]

      usage_message = "usage: rake forms:submission_type:set_to_email[<form_id>(, <submission_format>)*]".freeze
      abort usage_message if args[:form_id].blank?

      supported_formats = %w[csv json]
      abort "submission_format must be one of #{supported_formats.join(', ')}" unless submission_format.all? { supported_formats.include? it }

      form_id = args[:form_id]
      Rails.logger.info("Setting submission_type to email with submission_format #{submission_format} for form: #{form_id}")

      form = Form.find(form_id)
      form.submission_type = "email"
      form.submission_format = submission_format

      delivery_configuration = form.delivery_configurations.find_or_initialize_by(delivery_method: :email, delivery_schedule: :immediate)
      delivery_configuration.formats = submission_format
      delivery_configuration.save!

      form.delivery_configurations.where(delivery_method: :s3).destroy_all
      form.save!

      if form.is_live?
        form_document = form.live_form_document
        content = form_document.content

        content[:submission_type] = "email"
        content[:submission_format] = submission_format
        content[:delivery_configurations] = form.delivery_configurations.map(&:as_json)

        form_document.save!
      end

      Rails.logger.info("Set submission_type to email with submission_format #{submission_format} for form: #{form_id}")
    end

    desc "Set submission_type to s3"
    task :set_to_s3, %i[form_id s3_bucket_name s3_bucket_aws_account_id s3_bucket_region format] => :environment do |_, args|
      usage_message = "usage: rake forms:submission_type:set_to_s3[<form_id>, <s3_bucket_name>, <s3_bucket_aws_account_id>, <s3_bucket_region>, <format>]".freeze
      abort usage_message if args[:form_id].blank?
      abort usage_message if args[:s3_bucket_name].blank?
      abort usage_message if args[:s3_bucket_aws_account_id].blank?
      abort usage_message if args[:s3_bucket_region].blank?
      abort usage_message if args[:format].blank?
      abort "s3_bucket_region must be one of eu-west-1 or eu-west-2" unless %w[eu-west-1 eu-west-2].include? args[:s3_bucket_region]
      abort "format must be one of csv or json" unless %w[csv json].include? args[:format]

      submission_type = "s3"
      submission_format = [args[:format]]

      Rails.logger.info("Setting submission_type to #{submission_type} and s3_bucket_name to #{args[:s3_bucket_name]} for form: #{args[:form_id]}")
      form = Form.find(args[:form_id])
      form.submission_type = submission_type
      form.submission_format = submission_format
      form.s3_bucket_name = args[:s3_bucket_name]
      form.s3_bucket_aws_account_id = args[:s3_bucket_aws_account_id]
      form.s3_bucket_region = args[:s3_bucket_region]

      delivery_configuration = form.delivery_configurations.find_or_initialize_by(delivery_method: :s3, delivery_schedule: :immediate)
      delivery_configuration.formats = submission_format
      delivery_configuration.save!

      # For now, disable email delivery per submission. After we've migrated to using the DeliveryConfigurations in
      # forms-runner we can allow enabling both email and s3.
      form.delivery_configurations.where(delivery_method: :email, delivery_schedule: :immediate).destroy_all

      form.save!

      if form.is_live?
        form.form_documents.where(tag: "live").find_each do |form_document|
          content = form_document.content

          content[:submission_type] = submission_type
          content[:submission_format] = submission_format
          content[:s3_bucket_name] = args[:s3_bucket_name]
          content[:s3_bucket_aws_account_id] = args[:s3_bucket_aws_account_id]
          content[:s3_bucket_region] = args[:s3_bucket_region]
          content[:delivery_configurations] = form.delivery_configurations.map(&:as_json)

          form_document.save!
        end
      end

      Rails.logger.info("Set submission_type to #{submission_type} and s3_bucket_name to #{args[:s3_bucket_name]} for form: #{args[:form_id]}")
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

  desc "Show a form's form_document as JSON"
  task :show_form_document, %i[form_id tag language] => :environment do |_, args|
    usage_message = "usage: rake forms:show_form_document[<form_id>, <tag>, <language>]".freeze

    abort usage_message if args[:form_id].blank? || args[:tag].blank?
    language = args[:language].presence || "en"

    abort "tag must be one of draft, live or archived" unless %w[draft live archived].include?(args[:tag])
    abort "language must be en or cy" unless %w[en cy].include?(language)

    form = Form.find(args[:form_id])

    form_document = form.form_documents.find_by(tag: args[:tag], language:)
    abort "#{fmt_form(form)} does not have a #{args[:tag]} #{language} form document" if form_document.blank?

    puts JSON.pretty_generate(form_document.as_json)
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

def fmt_group(group)
  "group #{group.external_id} (\"#{group.name}\", #{group.organisation.name}, #{group.creator&.name || 'GOV.UK Forms Team'})"
end

def validate_email(email)
  NotificationsUtils::RecipientValidation::EmailAddress.validate_email_address(email)
  true
rescue NotificationsUtils::RecipientValidation::InvalidEmailError
  false
end
