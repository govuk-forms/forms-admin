class Reports::FormDocumentsService
  class << self
    def form_documents(tag:)
      form_documents = if tag == "draft"
                         FormDocument.joins(form: { group_form: { group: :organisation } })
                                     .where(version: nil, language: "en")
                       else
                         FormDocument.joins("INNER JOIN forms ON forms.latest_form_document_id = form_documents.id")
                                     .joins("INNER JOIN groups_form_ids ON groups_form_ids.form_id = forms.id")
                                     .joins("INNER JOIN groups ON groups.id = groups_form_ids.group_id")
                                     .joins("INNER JOIN organisations ON organisations.id = groups.organisation_id")
                       end

      form_documents = form_documents.where(forms: { "state": form_states_for_tag(tag) })
                                     .where.not(organisations: { "internal": true })
                                     .select("form_documents.*", "organisations.name AS organisation_name", "organisations.id AS organisation_id", "groups.external_id AS group_external_id", "groups.name AS group_name", "welsh_completed AS welsh_completed")

      form_documents.find_each(batch_size: 100).lazy.map(&:as_json)
    end

    def has_routes?(form_document)
      form_document["content"]["steps"].any? { |step| step["routing_conditions"].present? }
    end

    def has_secondary_skip_routes?(form_document)
      secondary_skip_conditions(form_document).any?
    end

    def count_secondary_skip_routes(form_document)
      secondary_skip_conditions(form_document).count
    end

    def step_has_secondary_skip_route?(form_document, step)
      secondary_skip_conditions(form_document).any? do |condition|
        condition["check_page_id"] == step["id"]
      end
    end

    def has_add_another_answer?(form_document)
      form_document["content"]["steps"].any? { |step| step["data"]["is_repeatable"] }
    end

    def has_payments?(form_document)
      form_document["content"]["payment_url"].present?
    end

    def has_csv_submission_email_attachments(form_document)
      form_document["content"]["delivery_configurations"].any? do |delivery_configuration|
        delivery_configuration["delivery_method"] == "email" &&
          delivery_configuration["delivery_schedule"] == "immediate" &&
          delivery_configuration["formats"].include?("csv")
      end
    end

    def has_json_submission_email_attachments(form_document)
      form_document["content"]["delivery_configurations"].any? do |delivery_configuration|
        delivery_configuration["delivery_method"] == "email" &&
          delivery_configuration["delivery_schedule"] == "immediate" &&
          delivery_configuration["formats"].include?("json")
      end
    end

    def has_daily_submission_csv(form_document)
      form_document["content"]["delivery_configurations"].any? { |c| c["delivery_schedule"] == "daily" }
    end

    def has_weekly_submission_csv(form_document)
      form_document["content"]["delivery_configurations"].any? { |c| c["delivery_schedule"] == "weekly" }
    end

    def has_s3_submissions(form_document)
      form_document["content"]["delivery_configurations"].any? { |c| c["delivery_method"] == "s3" }
    end

    def has_exit_pages?(form_document)
      form_document["content"]["steps"].any? do |step|
        step["exit_pages"]&.any? ||
          step["routing_conditions"]&.any? { |c| c["exit_page_markdown"].present? }
      end
    end

    def is_copy?(form_document)
      form_document["content"]["copied_from_id"].present?
    end

    def has_welsh_translation(form_document)
      form_document["welsh_completed"].present?
    end

    def copy_of_answers_enabled?(form_document)
      form_document.dig("content", "send_copy_of_answers") == "enabled"
    end

  private

    def form_states_for_tag(tag)
      {
        "draft" => %w[draft live_with_draft archived_with_draft],
        "live" => %w[live live_with_draft],
        "archived" => %w[archived archived_with_draft],
        "live-or-archived" => %w[live live_with_draft archived archived_with_draft],
      }[tag]
    end

    def secondary_skip_conditions(form_document)
      form_document["content"]["steps"].lazy.flat_map do |step|
        (step["routing_conditions"]&.lazy || []).reject do |condition|
          condition["check_page_id"] == condition["routing_page_id"]
        end
      end
    end
  end
end
