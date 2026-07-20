namespace :data_migrations do
  desc "create delivery configurations for existing forms"
  task create_delivery_configurations: :environment do
    updated_count = 0

    Form.all.find_each do |form|
      form.delivery_configurations.find_or_create_by!(
        delivery_method: form.submission_type,
        formats: form.submission_format,
        delivery_schedule: "immediate",
      )

      if form.send_daily_submission_batch
        form.delivery_configurations.find_or_create_by!(
          delivery_method: "email",
          formats: %w[csv],
          delivery_schedule: "daily",
        )
      end

      if form.send_weekly_submission_batch
        form.delivery_configurations.find_or_create_by!(
          delivery_method: "email",
          formats: %w[csv],
          delivery_schedule: "weekly",
        )
      end

      form.form_documents.each do |form_document|
        add_delivery_configurations_to_form_document(form, form_document)
      end

      updated_count += 1
    end

    Rails.logger.info("Updated #{updated_count} forms")
  end
end

def add_delivery_configurations_to_form_document(form, form_document)
  content = form_document.content

  delivery_configurations = []

  delivery_method = content["submission_type"]
  formats = content["submission_format"]
  delivery_configurations << DeliveryConfiguration.new(form:, delivery_method:, formats:, delivery_schedule: "immediate")

  if content["send_daily_submission_batch"]
    delivery_configurations << DeliveryConfiguration.new(form:, delivery_method: "email", formats: %w[csv], delivery_schedule: "daily")
  end

  if content["send_weekly_submission_batch"]
    delivery_configurations << DeliveryConfiguration.new(form:, delivery_method: "email", formats: %w[csv], delivery_schedule: "weekly")
  end

  content["delivery_configurations"] = delivery_configurations

  form_document.save!
end
