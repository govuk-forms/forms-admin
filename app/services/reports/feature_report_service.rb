class Reports::FeatureReportService
  attr_reader :form_documents

  def initialize(form_documents)
    @form_documents = form_documents
  end

  def report
    report = {
      total_forms: 0,
      copied_forms: 0,
      forms_with_payment: 0,
      forms_with_routing: 0,
      forms_with_add_another_answer: 0,
      forms_with_csv_submission_email_attachments: 0,
      forms_with_json_submission_email_attachments: 0,
      forms_with_daily_submission_csv: 0,
      forms_with_weekly_submission_csv: 0,
      forms_with_s3_submissions: 0,
      forms_with_answer_type: HashWithIndifferentAccess.new,
      steps_with_answer_type: HashWithIndifferentAccess.new,
      forms_with_exit_pages: 0,
      forms_with_welsh_translation: 0,
      forms_with_copy_of_answers_enabled: 0,
    }

    form_documents.each do |form|
      report[:total_forms] += 1
      report[:copied_forms] += 1 if Reports::FormDocumentsService.is_copy?(form)
      report[:forms_with_payment] += 1 if Reports::FormDocumentsService.has_payments?(form)
      report[:forms_with_routing] += 1 if Reports::FormDocumentsService.has_routes?(form)
      report[:forms_with_add_another_answer] += 1 if Reports::FormDocumentsService.has_add_another_answer?(form)
      report[:forms_with_csv_submission_email_attachments] += 1 if Reports::FormDocumentsService.has_csv_submission_email_attachments(form)
      report[:forms_with_json_submission_email_attachments] += 1 if Reports::FormDocumentsService.has_json_submission_email_attachments(form)
      report[:forms_with_daily_submission_csv] += 1 if Reports::FormDocumentsService.has_daily_submission_csv(form)
      report[:forms_with_weekly_submission_csv] += 1 if Reports::FormDocumentsService.has_weekly_submission_csv(form)
      report[:forms_with_s3_submissions] += 1 if Reports::FormDocumentsService.has_s3_submissions(form)
      report[:forms_with_exit_pages] += 1 if Reports::FormDocumentsService.has_exit_pages?(form)
      report[:forms_with_welsh_translation] += 1 if Reports::FormDocumentsService.has_welsh_translation(form)
      report[:forms_with_copy_of_answers_enabled] += 1 if Reports::FormDocumentsService.copy_of_answers_enabled?(form)

      answer_types_in_form = form["content"]["steps"].map { |step| step["data"]["answer_type"] }

      answer_types_in_form.uniq.each do |answer_type|
        report[:forms_with_answer_type][answer_type] ||= 0
        report[:forms_with_answer_type][answer_type] += 1
      end

      answer_types_in_form.each do |answer_type|
        report[:steps_with_answer_type][answer_type] ||= 0
        report[:steps_with_answer_type][answer_type] += 1
      end
    end

    report
  end

  def questions
    form_documents.flat_map do |form|
      form["content"]["steps"]
        .map { |step| questions_details(form, step) }
    end
  end

  def questions_with_answer_type(answer_type)
    form_documents.flat_map do |form|
      form["content"]["steps"]
        .select { |step| step["data"]["answer_type"] == answer_type }
        .map { |step| questions_details(form, step) }
    end
  end

  def questions_with_add_another_answer
    form_documents.flat_map do |form|
      form["content"]["steps"]
        .select { |step| step["data"]["is_repeatable"] }
        .map { |step| questions_details(form, step) }
    end
  end

  def selection_questions_with_autocomplete
    @form_documents.flat_map do |form|
      form["content"]["steps"]
        .select { |step|
          step["data"]["answer_type"] == "selection" &&
            step["data"]["answer_settings"]["only_one_option"] == "true" &&
            step["data"]["answer_settings"]["selection_options"].length > 30
        }
        .map { |step| questions_details(form, step) }
    end
  end

  def selection_questions_with_radios
    @form_documents.flat_map do |form|
      form["content"]["steps"]
        .select { |step|
          step["data"]["answer_type"] == "selection" &&
            step["data"]["answer_settings"]["only_one_option"] == "true" &&
            step["data"]["answer_settings"]["selection_options"].length <= 30
        }
        .map { |step| questions_details(form, step) }
    end
  end

  def selection_questions_with_checkboxes
    @form_documents.flat_map do |form|
      form["content"]["steps"]
        .select { |step|
          step["data"]["answer_type"] == "selection" &&
            step["data"]["answer_settings"]["only_one_option"] != "true"
        }
        .map { |step| questions_details(form, step) }
    end
  end

  def selection_questions_with_none_of_the_above
    @form_documents.flat_map do |form|
      form["content"]["steps"]
        .select { |step|
          step["data"]["answer_type"] == "selection" &&
            step["data"]["is_optional"] == true
        }
        .map { |step| questions_details(form, step) }
    end
  end

  def forms_that_are_copies
    form_documents.select { |form| Reports::FormDocumentsService.is_copy?(form) }
  end

  def forms_with_routes
    form_documents
      .select { |form| Reports::FormDocumentsService.has_routes?(form) }
      .map { |form| form_with_routes_details(form) }
  end

  def forms_with_payments
    form_documents
      .select { |form| Reports::FormDocumentsService.has_payments?(form) }
  end

  def forms_with_exit_pages
    form_documents
      .select { |form| Reports::FormDocumentsService.has_exit_pages?(form) }
  end

  def forms_with_csv_submission_email_attachments
    form_documents
      .select { |form| Reports::FormDocumentsService.has_csv_submission_email_attachments(form) }
  end

  def forms_with_json_submission_email_attachments
    form_documents
      .select { |form| Reports::FormDocumentsService.has_json_submission_email_attachments(form) }
  end

  def forms_with_daily_submission_csv
    form_documents
      .select { |form| Reports::FormDocumentsService.has_daily_submission_csv(form) }
  end

  def forms_with_weekly_submission_csv
    form_documents
      .select { |form| Reports::FormDocumentsService.has_weekly_submission_csv(form) }
  end

  def forms_with_s3_submissions
    form_documents
      .select { |form| Reports::FormDocumentsService.has_s3_submissions(form) }
  end

  def forms_with_welsh_translation
    form_documents
      .select { |form| Reports::FormDocumentsService.has_welsh_translation(form) }
  end

  def forms_with_copy_of_answers_enabled
    form_documents
      .select { |form| Reports::FormDocumentsService.copy_of_answers_enabled?(form) }
  end

private

  def questions_details(form, step)
    step.dup.merge("form" => form)
  end

  def form_with_routes_details(form)
    number_of_questions = {
      "with_routes" => 0,
      "with_many_conditional_routes" => 0,
    }

    form["content"]["steps"].each do |step|
      next unless step["routing_conditions"].any?

      number_of_questions["with_routes"] += 1

      if step["routing_conditions"].many? { |condition| condition["answer_value"].present? }
        number_of_questions["with_many_conditional_routes"] += 1
      end
    end

    form["metadata"] = {
      "number_of_questions" => number_of_questions,
    }

    form
  end
end
