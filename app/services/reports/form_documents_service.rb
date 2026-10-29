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

    def update_routes_details(form_document)
      number_of_questions = {
        "with_routes" => 0,
        "with_one_conditional_route" => 0,
        "with_many_conditional_routes" => 0,
        "with_unconditional_route" => 0,
      }

      form_document["content"]["steps"].each do |step|
        conditions = step["routing_conditions"]

        next unless conditions.any?

        number_of_questions["with_routes"] += 1

        conditional_routes_count = conditions.count { |condition| condition["answer_value"].present? }

        if conditional_routes_count == 1
          number_of_questions["with_one_conditional_route"] += 1
        elsif conditional_routes_count > 1
          number_of_questions["with_many_conditional_routes"] += 1
        end

        unconditional_route_present = conditions.any? { |condition| condition["answer_value"].nil? }

        if unconditional_route_present
          number_of_questions["with_unconditional_route"] += 1
        end
      end

      form_document["metadata"] = {
        "number_of_questions" => number_of_questions,
      }

      form_document
    end

    def has_routes?(form_document)
      form_document["content"]["steps"].any? { |step| step["routing_conditions"].present? }
    end

    def count_step_routes(step)
      step["routing_conditions"].count
    end

    def count_step_conditional_routes(step)
      step["routing_conditions"].count { |condition| condition["answer_value"].present? }
    end

    def count_step_unconditional_routes(step)
      step["routing_conditions"].count { |condition| condition["answer_value"].nil? }
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

    def count_exit_pages(form_document)
      form_document["content"]["steps"].sum { |step| count_step_exit_pages(step) }
    end

    def count_step_exit_pages(step)
      if step["exit_pages"]&.any?
        step["exit_pages"].length
      else
        step["routing_conditions"]&.count { |c| c["exit_page_markdown"].present? } || 0
      end
    end

    def has_question_with_multiple_exit_pages?(form_document)
      form_document["content"]["steps"].any? { |step| count_step_exit_pages(step) > 1 }
    end

    def has_question_with_multiple_routes_to_exit_pages?(form_document)
      form_document["content"]["steps"].any? do |step|
        (step["routing_conditions"]&.count { |condition| condition["exit_page_id"].present? } || 0) > 1
      end
    end

    def count_unreachable_exit_pages(step)
      return 0 unless step["exit_pages"]&.any?

      routed_exit_page_ids = (step["routing_conditions"] || []).filter_map { |condition| condition["exit_page_id"] }
      step["exit_pages"].count { |exit_page| routed_exit_page_ids.exclude?(exit_page["id"]) }
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

    # The feature flags for a form document, keyed by the feature report
    # counters without their forms_with_ prefix. Every value is a boolean.
    def features(form_document)
      routes = has_routes?(form_document)
      counts = update_routes_details(form_document).dig("metadata", "number_of_questions") if routes

      {
        "copied" => is_copy?(form_document),
        "payment" => has_payments?(form_document),
        "routing" => routes,
        "only_steps_with_one_conditional_route" => routes && counts["with_one_conditional_route"].positive? && counts["with_many_conditional_routes"].zero?,
        "steps_with_many_conditional_routes" => routes && counts["with_many_conditional_routes"].positive?,
        "only_unconditional_routes" => routes && counts["with_routes"] == counts["with_unconditional_route"],
        "add_another_answer" => has_add_another_answer?(form_document),
        "csv_submission_email_attachments" => has_csv_submission_email_attachments(form_document),
        "json_submission_email_attachments" => has_json_submission_email_attachments(form_document),
        "daily_submission_csv" => has_daily_submission_csv(form_document),
        "weekly_submission_csv" => has_weekly_submission_csv(form_document),
        "s3_submissions" => has_s3_submissions(form_document),
        "exit_pages" => has_exit_pages?(form_document),
        "welsh_translation" => has_welsh_translation(form_document),
        "copy_of_answers_enabled" => copy_of_answers_enabled?(form_document),
      }
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
  end
end
