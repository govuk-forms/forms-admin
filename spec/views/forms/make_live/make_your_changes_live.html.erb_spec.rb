require "rails_helper"

describe "forms/make_live/make_your_changes_live.html.erb" do
  let(:current_form) { OpenStruct.new(id: 1, name: "Form 1", form_slug: "form-1") }
  let(:make_live_input) { Forms::MakeLiveInput.new(form: current_form) }

  before do
    assign(:make_live_input, make_live_input)

    without_partial_double_verification do
      allow(view).to receive_messages(form_path: "/forms/1", make_live_create_path: "forms/1/make-live")
    end
  end

  context "when there are no errors" do
    before do
      render template: "forms/make_live/make_your_changes_live", locals: { current_form: }
    end

    it "has the correct page title" do
      expect(view.content_for(:title)).to eq t("page_titles.make_changes_live")
    end

    it "contains a heading" do
      expect(rendered).to have_css("h1", text: t("page_titles.make_changes_live"))
    end

    it "contains a warning about the impact on form fillers" do
      expect(rendered).to have_css("p", text: I18n.t("make_changes_live.warning"))
    end

    context "when the live form has save and return enabled" do
      let(:current_form) { OpenStruct.new(id: 1, name: "Form 1", form_slug: "form-1", "live_save_and_return_enabled?": true) }

      it "contains a warning about the impact on form fillers who have and have not saved their progress" do
        expect(rendered).to include(I18n.t("make_changes_live.warning_with_save_and_return_html"))
      end
    end

    it "contains information about the form's URL" do
      expect(rendered).to have_css("p", text: I18n.t("make_changes_live.url_will_remain_same"))
    end

    context "when the form has no Welsh translation" do
      it "does not contain a reminder about keeping the welsh translation up to date" do
        expect(rendered).not_to have_css("p", text: /Welsh/)
      end
    end

    context "when the form has a Welsh translation" do
      let(:current_form) { OpenStruct.new(id: 1, name: "Form 1", form_slug: "form-1", "has_welsh_translation?": true) }

      it "contains a reminder about keeping the welsh translation up to date" do
        expect(rendered).to have_css("p", text: I18n.t("make_changes_live.welsh_reminder"))
      end
    end

    it "renders radio buttons for making the draft changes live" do
      expect(rendered).to have_css("legend", text: I18n.t("helpers.label.forms_make_changes_live.confirm"))
      expect(rendered).to have_field("Yes", type: "radio")
      expect(rendered).to have_field("No", type: "radio")
    end

    it "renders a submit button" do
      expect(rendered).to have_css("button", text: I18n.t("save_and_continue"))
    end
  end

  context "when there are errors" do
    before do
      make_live_input.errors.add(:confirm, "An error")

      assign(:make_live_input, make_live_input)
      render template: "forms/make_live/make_your_changes_live", locals: { current_form: }
    end

    it "displays the error summary" do
      expect(rendered).to have_selector(".govuk-error-summary")
    end

    it "displays an inline error message" do
      expect(rendered).to have_css(".govuk-error-message")
    end

    it "sets the page title with error prefix" do
      expect(view.content_for(:title)).to eq(title_with_error_prefix(t("page_titles.make_changes_live"), true))
    end
  end
end
