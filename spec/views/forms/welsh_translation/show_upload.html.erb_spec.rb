require "rails_helper"

describe "forms/welsh_translation/show_upload.html.erb" do
  let(:form) { create :form }
  let(:welsh_translation_upload_input) { Forms::WelshTranslationUploadInput.new(form: form) }

  before do
    render template: "forms/welsh_translation/show_upload", locals: {
      current_form: form,
      welsh_translation_upload_input: welsh_translation_upload_input,
    }
  end

  it "contains a top-level heading" do
    expect(rendered).to have_css("h1", text: I18n.t("page_titles.welsh_translation_upload"))
  end

  it "has a back link to the welsh translation page" do
    expect(view.content_for(:back_link)).to have_link("Back", href: welsh_translation_path(form))
  end

  it "contains a form for uploading a Welsh translation CSV file" do
    expect(rendered).to have_css("form[action='#{welsh_translation_upload_path(form)}'][method='post'][enctype='multipart/form-data']")
  end

  it "contains a file input field for uploading the CSV file" do
    expect(rendered).to have_css("input[type='file'][name='forms_welsh_translation_upload_input[file]'][accept='text/csv']")
  end

  it "has the correct label for the file input field" do
    expect(rendered).to have_css("label[for='forms-welsh-translation-upload-input-file-field']", text: I18n.t("helpers.label.forms_welsh_translation_upload_input.file"))
  end

  it "has the correct hint text" do
    expect(rendered).to have_css(".govuk-hint", text: I18n.t("helpers.hint.forms_welsh_translation_upload_input.file"))
  end

  context "when the form has errors" do
    before do
      welsh_translation_upload_input.errors.add(:file, "an error occurred")
      render template: "forms/welsh_translation/show_upload", locals: {
        current_form: form,
        welsh_translation_upload_input: welsh_translation_upload_input,
      }
    end

    it "displays the error message" do
      expect(rendered).to have_css(".govuk-error-summary")
      expect(rendered).to have_css(".govuk-error-message", text: "an error occurred")
    end
  end

  context "when there are errors and an error_row_number is set" do
    before do
      welsh_translation_upload_input.errors.add(:file, "an error occurred")
      welsh_translation_upload_input.error_row_number = 2
      render template: "forms/welsh_translation/show_upload", locals: {
        current_form: form,
        welsh_translation_upload_input: welsh_translation_upload_input,
      }
    end

    it "includes the row number in the error summary title" do
      expect(rendered).to have_css(".govuk-error-summary__title", text: I18n.t("forms.welsh_translation.show_upload.error_summary_title_with_row_number", row_number: 2))
      expect(rendered).to have_css(".govuk-error-message", text: "an error occurred")
    end
  end
end
