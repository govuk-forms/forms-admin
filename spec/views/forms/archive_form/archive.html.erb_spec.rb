require "rails_helper"

describe "forms/archive_form/archive.html.erb" do
  let(:id) { 2 }
  let(:form) { build(:form, :live, id:) }
  let(:confirm_archive_input) { Forms::ConfirmArchiveInput.new(form:) }

  before do
    assign(:confirm_archive_input, confirm_archive_input)
  end

  context "when there are no errors" do
    before do
      render
    end

    it "displays the form" do
      expect(rendered).to have_selector("form[action='#{archive_form_update_path(id)}'][method='post']")
      expect(rendered).to have_field("forms_confirm_archive_input[confirm]")
      expect(rendered).to have_button("Save and continue")
    end
  end

  context "when the live form has save and return enabled" do
    before do
      allow(form).to receive(:live_save_and_return_enabled?).and_return(true)
      render
    end

    it "explains what happens to people who have and have not saved their progress" do
      expect(rendered).to include(I18n.t("archive_form.confirm.body_with_save_and_return_html", submission_email: form.submission_email))
    end
  end

  context "when there are errors" do
    before do
      confirm_archive_input.errors.add(:confirm, "is required")
      render
    end

    it "displays the error summary" do
      expect(rendered).to have_selector(".govuk-error-summary")
    end

    it "sets the page title with error prefix" do
      expect(view.content_for(:title)).to eq(title_with_error_prefix("Archive this form", true))
    end
  end
end
