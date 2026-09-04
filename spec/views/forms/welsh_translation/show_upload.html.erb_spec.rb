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
end
