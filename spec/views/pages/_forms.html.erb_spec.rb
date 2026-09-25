require "rails_helper"

describe "pages/_form.html.erb", type: :view do
  let(:page) { build :page, :with_hints, :with_simple_answer_type, id: 2, form_id: form.id }
  let(:draft_question) { question_input.draft_question }
  let(:question_input) do
    build :question_input,
          answer_type: page.answer_type,
          question_text: page.question_text,
          hint_text: page.hint_text,
          answer_settings: page.answer_settings
  end
  let(:form) { create :form }
  let(:group) { create :group }
  let(:is_new_page) { true }
  let(:locals) do
    { is_new_page:,
      form_object: form,
      page_object: page,
      draft_question:,
      question_input:,
      action_path: "http://example.com" }
  end

  before do
    GroupForm.create!(group:, form_id: form.id)
    render partial: "pages/form", locals:
  end

  it "has a form with correct action" do
    expect(rendered).to have_selector('form[action="http://example.com"]')
  end

  it "has a field with the question text" do
    expect(rendered).to have_field(type: "text", with: question_input.question_text)
    expect(rendered).to have_text(I18n.t("helpers.label.pages_question_input.question_text.default"))
  end

  it "has a field with the hint text" do
    expect(rendered).to have_field(type: "textarea", with: question_input.hint_text)
  end

  it "has an unchecked optional checkbox" do
    expect(rendered).to have_unchecked_field("pages_question_input[is_optional]")
  end

  it "has a radio input for repeatable" do
    expect(rendered).to have_field("pages_question_input[is_repeatable]", type: :radio)
  end

  it "has a details about repeatable questions" do
    expect(rendered).to have_text(I18n.t("repeatable.summary_text"))
  end

  context "when the question is an only one option selection" do
    let(:page) { build :page, :with_selection_settings, id: 2, form_id: form.id }

    it "does not have the radio input for repeatable" do
      expect(rendered).not_to have_field("pages_question_input[is_repeatable]", type: :radio)
    end
  end

  context "when the question is an only more than one option selection" do
    let(:page) { build :page, :with_selection_settings, only_one_option: false, id: 2, form_id: form.id }

    it "does not have the radio input for repeatable" do
      expect(rendered).not_to have_field("pages_question_input[is_repeatable]", type: :radio)
    end
  end

  it "has a submit button to save the question" do
    expect(rendered).to have_button(I18n.t("pages.submit_save"), name: "submit_type", value: "save")
  end

  it "does not have a delete button" do
    expect(rendered).not_to have_button("delete")
  end

  it "has a submit button to add guidance" do
    expect(rendered).to have_button(text: I18n.t("guidance.add_guidance"), name: "submit_type", value: "add_guidance")
  end

  it "contains a hint for guidance" do
    expect(rendered).to have_text(I18n.t("helpers.hint.page.guidance.default"))
  end

  context "when it is not a new page" do
    let(:is_new_page) { false }

    it "has no hidden field for the answer type" do
      expect(rendered).not_to have_field("question_input[answer_type]", type: :hidden)
    end

    it "has a delete button" do
      expect(rendered).to have_link(text: I18n.t("pages.delete_question"), href: delete_page_path(form_id: form.id, page_id: page.id))
    end
  end

  context "when the page has existing guidance" do
    let(:draft_question) { build :draft_question, :with_guidance }
    let(:question_input) do
      build :question_input,
            draft_question:,
            answer_type: page.answer_type,
            answer_settings: page.answer_settings,
            question_text: page.question_text,
            hint_text: page.hint_text
    end

    before do
      allow(PageSummaryData::GuidanceService).to receive(:call).and_call_original

      render partial: "pages/form", locals:
    end

    it "calls the PageSummaryData::GuidanceService with the form and draft_question" do
      expect(PageSummaryData::GuidanceService).to have_received(:call).with(form:, draft_question:)
    end

    it "renders the draft question guidance page heading" do
      expect(rendered).to have_text(draft_question.page_heading)
    end

    it "renders the draft question guidance markdown" do
      expect(rendered).to have_text(draft_question.guidance_markdown)
    end
  end

  it "does not display the file body text" do
    expect(rendered).not_to have_text(I18n.t("helpers.label.pages_question_input.file_body_html"))
    expect(rendered).not_to have_text(I18n.t("helpers.label.pages_question_input.summary"))
  end

  context "when the answer type is file" do
    let(:page) { build :page, :with_hints, answer_type: "file", id: 2, form_id: form.id }
    let(:draft_question) { build :draft_question, answer_type: "file" }
    let(:question_input) do
      build :question_input,
            answer_type: page.answer_type,
            question_text: page.question_text,
            hint_text: page.hint_text,
            answer_settings: page.answer_settings,
            draft_question:
    end

    it "displays the file body text" do
      expect(rendered).to include(I18n.t("helpers.label.pages_question_input.file.body_html"))
      expect(rendered).to have_text(I18n.t("helpers.label.pages_question_input.file.details_title"))
      expect(rendered).to include(I18n.t("helpers.label.pages_question_input.file.details_body_html"))
    end

    it "has a field with the file question text" do
      expect(rendered).to have_text(I18n.t("helpers.label.pages_question_input.question_text.file"))
    end

    it "contains a hint for guidance" do
      expect(rendered).to have_text(I18n.t("helpers.hint.page.guidance.file"))
    end

    it "does not have the radio input for repeatable" do
      expect(rendered).not_to have_field("pages_question_input[is_repeatable]", type: :radio)
    end
  end
end
