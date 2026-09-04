module WelshTranslationContentLabels
  FORM_ATTRIBUTE_LABELS = {
    name: "Form name",
    declaration_markdown: "Declaration",
    what_happens_next_markdown: "Information about what happens next",
    payment_url: "GOV.UK Pay payment link",
    privacy_policy_url: "Link to privacy information for this form",
    support_email: "Contact details for support - email address",
    support_phone: "Contact details for support - phone number and opening times",
    support_url: "Contact details for support - online contact link",
    support_url_text: "Contact details for support - online contact link text",
  }.freeze

  PAGE_ATTRIBUTE_LABELS = {
    question_text: "question text",
    hint_text: "hint text",
    page_heading: "page heading",
    guidance_markdown: "guidance text",
    none_of_the_above_question: "question or label if 'None of the above' is selected",
  }.freeze

  CONDITION_ATTRIBUTE_LABELS = {
    exit_page_heading: "exit page heading",
    exit_page_markdown: "exit page content",
  }.freeze

  EXIT_PAGE_ATTRIBUTE_LABELS = {
    heading: "heading",
    markdown: "content",
  }.freeze

  def page_label(page, attribute)
    "#{question_name(page)} - #{PAGE_ATTRIBUTE_LABELS.fetch(attribute)}"
  end

  def selection_option_label(page, option_index)
    "#{question_name(page)} - option #{option_index + 1}"
  end

  def condition_label(page, attribute)
    "#{question_name(page)} - #{CONDITION_ATTRIBUTE_LABELS.fetch(attribute)}"
  end

  def exit_page_label(page, exit_page_position, attribute)
    "#{question_name(page)} - exit page #{exit_page_position} #{EXIT_PAGE_ATTRIBUTE_LABELS.fetch(attribute)}"
  end

  def question_name(page)
    "Question #{page.position}"
  end
end
