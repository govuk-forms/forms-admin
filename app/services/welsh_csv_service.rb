class WelshCsvService
  include WelshTranslationContentId

  MAX_FILENAME_LENGTH = 80
  FILENAME_SEPARATOR = "_".freeze

  attr_reader :form

  def initialize(form)
    @form = form
  end

  def as_csv
    CSV.generate do |csv|
      add_header(csv)
      add_form_name(csv)
      add_page_content(csv)
      add_form_metadata(csv)
    end
  end

  def filename
    extension = ".csv"
    safe_form_name = form.name
      .parameterize(separator: FILENAME_SEPARATOR)
      .truncate(MAX_FILENAME_LENGTH - extension.length, separator: FILENAME_SEPARATOR, omission: "")

    "#{safe_form_name}#{extension}"
  end

private

  def add_header(csv)
    csv << [WelshSpreadsheetImportService::ID_COLUMN, "Content", "English content", "Welsh content"]
  end

  def add_form_name(csv)
    csv << ["name", "Form name", form.name, form.name_cy]
  end

  def add_page_content(csv)
    form.pages.each do |page|
      add_page_heading(csv, page)
      add_guidance_text(csv, page)
      add_question_content(csv, page)
      add_selection_options(csv, page) if page.answer_type == "selection"
      add_none_of_above_question(csv, page) if has_none_of_the_above?(page)
      add_routing_conditions(csv, page)
    end
  end

  def add_question_content(csv, page)
    csv << [page_content_id(page.id, :question_text), "#{question_name(page)} - question text", page.question_text, page.question_text_cy]
    if page.hint_text.present?
      csv << [page_content_id(page.id, :hint_text), "#{question_name(page)} - hint text", page.hint_text, page.hint_text_cy]
    end
  end

  def add_selection_options(csv, page)
    page.answer_settings.selection_options.each_with_index do |option, index|
      welsh_option_name = page.answer_settings_cy&.selection_options&.dig(index)&.name || ""
      csv << [page_content_id(page.id, "option_#{index}"), "#{question_name(page)} - option #{index + 1}", option.name, welsh_option_name]
    end
  end

  def add_none_of_above_question(csv, page)
    english_question = page.answer_settings.none_of_the_above_question.question_text
    welsh_question = page.answer_settings_cy&.none_of_the_above_question&.question_text || ""

    csv << [
      page_content_id(page.id, :none_of_the_above_question),
      "#{question_name(page)} - question or label if 'None of the above' is selected",
      english_question,
      welsh_question,
    ]
  end

  def has_none_of_the_above?(page)
    page.answer_type == "selection" &&
      page.answer_settings.none_of_the_above_question.present?
  end

  def add_routing_conditions(csv, page)
    page.routing_conditions.each do |condition|
      if condition.is_exit_page?
        csv << [condition_content_id(condition.id, :exit_page_heading), "#{question_name(page)} - exit page heading", condition.exit_page_heading, condition.exit_page_heading_cy]
        csv << [condition_content_id(condition.id, :exit_page_markdown), "#{question_name(page)} - exit page content", condition.exit_page_markdown, condition.exit_page_markdown_cy]
      end
    end
  end

  def add_page_heading(csv, page)
    if page.page_heading.present?
      csv << [page_content_id(page.id, :page_heading), "#{question_name(page)} - page heading", page.page_heading, page.page_heading_cy]
    end
  end

  def add_guidance_text(csv, page)
    if page.guidance_markdown.present?
      csv << [page_content_id(page.id, :guidance_markdown), "#{question_name(page)} - guidance text", page.guidance_markdown, page.guidance_markdown_cy]
    end
  end

  def question_name(page)
    "Question #{page.position}"
  end

  def add_form_metadata(csv)
    add_field_if_present(csv, "declaration_markdown", "Declaration", form.declaration_text, form.declaration_text_cy)
    add_field_if_present(csv, "what_happens_next_markdown", "Information about what happens next", form.what_happens_next_markdown, form.what_happens_next_markdown_cy)
    add_field_if_present(csv, "payment_url", "GOV\u2060.\u2060UK Pay payment link", form.payment_url, form.payment_url_cy)
    add_field_if_present(csv, "privacy_policy_url", "Link to privacy information for this form", form.privacy_policy_url, form.privacy_policy_url_cy)

    add_support_details(csv)
  end

  def add_support_details(csv)
    add_field_if_present(csv, "support_email", "Contact details for support - email address", form.support_email, form.support_email_cy)
    add_field_if_present(csv, "support_phone", "Contact details for support - phone number and opening times", form.support_phone, form.support_phone_cy)
    add_field_if_present(csv, "support_url", "Contact details for support - online contact link", form.support_url, form.support_url_cy)
    add_field_if_present(csv, "support_url_text", "Contact details for support - online contact link text", form.support_url_text, form.support_url_text_cy)
  end

  def add_field_if_present(csv, id, label, english_value, welsh_value)
    if english_value.present?
      csv << [id, label, english_value, welsh_value || ""]
    end
  end
end
