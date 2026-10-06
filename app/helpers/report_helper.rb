module ReportHelper
  def report_table(type, records)
    case type
    when :forms
      report_forms_table(records)
    when :forms_with_routes
      report_forms_with_routes_table(records)
    when :questions
      report_questions_table(records)
    when :selection_questions
      report_selection_questions_table(records)
    when :selection_questions_with_none_of_the_above
      report_selection_questions_with_none_of_the_above_table(records)
    else
      raise "type '#{type}' is not expected"
    end
  end

  def report_forms_table(forms)
    {
      head: report_forms_table_head,
      rows: report_forms_table_rows(forms),
    }
  end

  def report_forms_with_routes_table(forms)
    {
      head: report_forms_with_routes_table_head,
      rows: report_forms_with_routes_table_rows(forms),
    }
  end

  def report_questions_table(questions)
    {
      head: report_questions_table_head,
      rows: report_questions_table_rows(questions),
    }
  end

  def report_selection_questions_table(questions)
    {
      head: report_selection_questions_table_head,
      rows: report_selection_questions_table_rows(questions),
    }
  end

  def report_selection_questions_with_none_of_the_above_table(questions)
    {
      head: report_selection_questions_with_none_of_the_above_table_head,
      rows: report_selection_questions_with_none_of_the_above_table_rows(questions),
    }
  end

  def report_forms_table_head
    [
      I18n.t("reports.form_or_questions_list_table.headings.form_name"),
      I18n.t("reports.form_or_questions_list_table.headings.organisation"),
    ]
  end

  def report_forms_table_rows(forms)
    forms.map { |form| report_forms_table_row(form) }
  end

  def report_forms_with_routes_table_head
    [
      *report_forms_table_head,
      I18n.t("reports.form_or_questions_list_table.headings.number_of_questions.with_routes"),
      I18n.t("reports.form_or_questions_list_table.headings.number_of_questions.with_one_conditional_route"),
      I18n.t("reports.form_or_questions_list_table.headings.number_of_questions.with_many_conditional_routes"),
      I18n.t("reports.form_or_questions_list_table.headings.number_of_questions.with_unconditional_route"),
    ]
  end

  def report_forms_with_routes_table_rows(forms)
    forms.map { |form| report_forms_with_routes_table_row(form) }
  end

  def report_questions_table_head
    [
      *report_forms_table_head,
      I18n.t("reports.form_or_questions_list_table.headings.question_text"),
    ]
  end

  def report_questions_table_rows(questions)
    questions.map { |question| report_questions_table_row(question) }
  end

  def tag_label(tag)
    t("reports.tag_labels.#{tag}")
  end

  def none_of_the_above_question_text(question)
    none_of_the_above_question = question.dig("data", "answer_settings", "none_of_the_above_question")

    if none_of_the_above_question.blank?
      return I18n.t("reports.form_or_questions_list_table.values.no_follow_up_question")
    end

    if ActiveRecord::Type::Boolean.new.cast(none_of_the_above_question["is_optional"])
      I18n.t("step_summary_card.none_of_the_above_question_optional", question_text: none_of_the_above_question["question_text"])
    else
      none_of_the_above_question["question_text"]
    end
  end

private

  def report_forms_table_row(form)
    [
      form_link(form),
      form["organisation_name"],
    ]
  end

  def report_forms_with_routes_table_row(form)
    [
      *report_forms_table_row(form),
      form["metadata"]["number_of_questions"]["with_routes"].to_s,
      form["metadata"]["number_of_questions"]["with_one_conditional_route"].to_s,
      form["metadata"]["number_of_questions"]["with_many_conditional_routes"].to_s,
      form["metadata"]["number_of_questions"]["with_unconditional_route"].to_s,
    ]
  end

  def report_questions_table_row(question)
    [
      *report_forms_table_row(question["form"]),
      question["data"]["question_text"],
    ]
  end

  def report_selection_questions_table_head
    [
      *report_questions_table_head,
      I18n.t("reports.form_or_questions_list_table.headings.number_of_options"),
      I18n.t("reports.form_or_questions_list_table.headings.none_of_the_above"),
    ]
  end

  def report_selection_questions_with_none_of_the_above_table_head
    [
      *report_questions_table_head,
      I18n.t("reports.form_or_questions_list_table.headings.none_of_the_above_follow_up_question"),
    ]
  end

  def report_selection_questions_table_rows(questions)
    questions.map { |question| report_selection_questions_table_row(question) }
  end

  def report_selection_questions_table_row(question)
    selection_options_count = question.dig("data", "answer_settings", "selection_options").length.to_s
    none_of_the_above = question["data"]["is_optional"] ? I18n.t("reports.form_or_questions_list_table.values.yes") : I18n.t("reports.form_or_questions_list_table.values.no")
    [
      *report_questions_table_row(question),
      selection_options_count,
      none_of_the_above,
    ]
  end

  def report_selection_questions_with_none_of_the_above_table_rows(questions)
    questions.map { |question| report_selection_questions_with_none_of_the_above_table_row(question) }
  end

  def report_selection_questions_with_none_of_the_above_table_row(question)
    [
      *report_questions_table_row(question),
      none_of_the_above_question_text(question),
    ]
  end

  def form_link(form)
    form_id = form["form_id"]
    form_name = form["content"]["name"]
    pages_path = case form["tag"]
                 when "draft"
                   form_pages_path(form_id:)
                 when "live"
                   live_form_pages_path(form_id:)
                 when "archived"
                   archived_form_pages_path(form_id:)
                 else
                   raise "tag of form record '#{form['tag']}' is not expected"
                 end

    govuk_link_to(form_name, pages_path)
  end
end
