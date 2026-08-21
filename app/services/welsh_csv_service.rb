class WelshCsvService
  include WelshTranslationContentLabels

  MAX_FILENAME_LENGTH = 80
  FILENAME_SEPARATOR = "_".freeze
  CONTENT_ID_HEADER = "Content ID".freeze
  ENGLISH_CONTENT_HEADER = "English content".freeze
  WELSH_CONTENT_HEADER = "Welsh content".freeze

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
    csv << [CONTENT_ID_HEADER, ENGLISH_CONTENT_HEADER, WELSH_CONTENT_HEADER]
  end

  def add_form_name(csv)
    csv << ["Form name", form.name, form.name_cy]
  end

  def add_page_content(csv)
    form.pages.each do |page|
      add_page_heading(csv, page)
      add_guidance_text(csv, page)
      add_question_content(csv, page)
      add_selection_options(csv, page) if page.answer_type == "selection"
      add_none_of_above_question(csv, page) if has_none_of_the_above?(page)

      if FeatureService.new(group: form.group).enabled?(:multiple_branches)
        add_exit_pages(csv, page)
      else
        add_routing_conditions(csv, page)
      end
    end
  end

  def add_question_content(csv, page)
    csv << [page_label(page, :question_text), page.question_text, page.question_text_cy]
    if page.hint_text.present?
      csv << [page_label(page, :hint_text), page.hint_text, page.hint_text_cy]
    end
  end

  def add_selection_options(csv, page)
    page.answer_settings.selection_options.each_with_index do |option, index|
      welsh_option_name = page.answer_settings_cy&.selection_options&.dig(index)&.name || ""
      csv << [selection_option_label(page, index), option.name, welsh_option_name]
    end
  end

  def add_none_of_above_question(csv, page)
    english_question = page.answer_settings.none_of_the_above_question.question_text
    welsh_question = page.answer_settings_cy&.none_of_the_above_question&.question_text || ""

    csv << [
      page_label(page, :none_of_the_above_question),
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
        csv << [condition_label(page, :exit_page_heading), condition.exit_page_heading, condition.exit_page_heading_cy]
        csv << [condition_label(page, :exit_page_markdown), condition.exit_page_markdown, condition.exit_page_markdown_cy]
      end
    end
  end

  def add_exit_pages(csv, page)
    exit_page_positions = ExitPage.positions_for_page(page)
    page.exit_pages.each do |exit_page|
      exit_page_position = exit_page_positions[exit_page.id]
      csv << [exit_page_label(page, exit_page_position, :heading), exit_page.heading, exit_page.heading_cy]
      csv << [exit_page_label(page, exit_page_position, :markdown), exit_page.markdown, exit_page.markdown_cy]
    end
  end

  def add_page_heading(csv, page)
    if page.page_heading.present?
      csv << [page_label(page, :page_heading), page.page_heading, page.page_heading_cy]
    end
  end

  def add_guidance_text(csv, page)
    if page.guidance_markdown.present?
      csv << [page_label(page, :guidance_markdown), page.guidance_markdown, page.guidance_markdown_cy]
    end
  end

  def question_name(page)
    "Question #{page.position}"
  end

  def add_form_metadata(csv)
    add_field_if_present(csv, FORM_ATTRIBUTE_LABELS[:declaration_markdown], form.declaration_text, form.declaration_text_cy)
    add_field_if_present(csv, FORM_ATTRIBUTE_LABELS[:what_happens_next_markdown], form.what_happens_next_markdown, form.what_happens_next_markdown_cy)
    add_field_if_present(csv, FORM_ATTRIBUTE_LABELS[:payment_url], form.payment_url, form.payment_url_cy)
    add_field_if_present(csv, FORM_ATTRIBUTE_LABELS[:privacy_policy_url], form.privacy_policy_url, form.privacy_policy_url_cy)

    add_support_details(csv)
  end

  def add_support_details(csv)
    add_field_if_present(csv, FORM_ATTRIBUTE_LABELS[:support_email], form.support_email, form.support_email_cy)
    add_field_if_present(csv, FORM_ATTRIBUTE_LABELS[:support_phone], form.support_phone, form.support_phone_cy)
    add_field_if_present(csv, FORM_ATTRIBUTE_LABELS[:support_url], form.support_url, form.support_url_cy)
    add_field_if_present(csv, FORM_ATTRIBUTE_LABELS[:support_url_text], form.support_url_text, form.support_url_text_cy)
  end

  def add_field_if_present(csv, label, english_value, welsh_value)
    if english_value.present?
      csv << [label, english_value, welsh_value || ""]
    end
  end
end
