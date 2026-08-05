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

  namespace :delivery_configurations do
    desc "Enable email delivery for submissions"
    task :enable_email, %i[form_id] => :environment do |_, args|
      usage_message = "usage: rake forms:delivery_configurations:enable_email[<form_id>]".freeze
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
      usage_message = "usage: rake forms:delivery_configurations:disable_email[<form_id>]".freeze
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
      usage_message = "usage: rake forms:delivery_configurations:disable_s3[<form_id>]".freeze
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
      usage_message = "usage: rake forms:delivery_configurations:enable_s3[<form_id>, <s3_bucket_name>, <s3_bucket_aws_account_id>, <s3_bucket_region>, <format>, <disable_email>]".freeze
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
