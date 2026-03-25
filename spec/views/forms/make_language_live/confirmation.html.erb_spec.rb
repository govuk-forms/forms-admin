require "rails_helper"

describe "forms/make_language_live/confirmation.html.erb" do
  let(:has_welsh_translation) { false }
  let(:welsh_completed) { false }
  let(:go_to_make_welsh_live_input) { Forms::GoToMakeWelshLiveInput.new }
  let(:current_form) { OpenStruct.new(id: 1, name: "Form 1", name_cy: "Ffurflen 1", form_slug: "form-1", has_welsh_translation?: has_welsh_translation, welsh_completed:) }
  let(:language) { "en" }

  before do
    assign(:go_to_make_welsh_live_input, go_to_make_welsh_live_input)
    render template: "forms/make_language_live/confirmation", locals: { current_form:, confirmation_page_title: "Your form is live", confirmation_page_body: I18n.t("make_changes_live.confirmation.body_html").html_safe, language: }
  end

  context "when the language made live was English" do
    it "contains a confirmation panel with a title" do
      expect(rendered).to have_css(".govuk-panel--confirmation h1", text: /Your form is live/)
    end

    it "contains the URL of the live form" do
      expect(rendered).to have_text("runner-host/form/1/form-1")
    end

    it "contains a link to the live form details" do
      expect(rendered).to have_link("Continue to the live form’s details", href: live_form_path(1))
    end

    it "displays form name as plain text" do
      expect(rendered).to have_css("h2", text: "English form name")
      expect(rendered).to have_css("p", text: "Form 1")
      expect(rendered).not_to have_css(".govuk-summary-list")
    end

    it "displays the Form URL heading and button text" do
      expect(rendered).to have_css("h2", text: t("make_live.confirmation.english_form_url"))
      expect(rendered).to have_css("[data-copy-button-text='#{t('make_live.confirmation.copy_english_url_to_clipboard')}']")
    end

    context "when the form has a completed Welsh version" do
      let(:has_welsh_translation) { true }
      let(:welsh_completed) { true }

      it "renders radio buttons for making the draft changes live" do
        expect(rendered).to have_css("legend", text: I18n.t("helpers.legend.forms_go_to_make_welsh_live_input.confirm"))
        expect(rendered).to have_field(t("helpers.label.forms_go_to_make_welsh_live_input.confirm_options.yes"), type: "radio")
        expect(rendered).to have_field(t("helpers.label.forms_go_to_make_welsh_live_input.confirm_options.no"), type: "radio")
      end
    end
  end

  context "when the language made live was Welsh" do
    let(:language) { "cy" }

    it "contains a confirmation panel with a title" do
      expect(rendered).to have_css(".govuk-panel--confirmation h1", text: /Your form is live/)
    end

    it "contains the URL of the live form" do
      expect(rendered).to have_text("runner-host/form/1/form-1.cy")
    end

    it "contains a link to the live form details" do
      expect(rendered).to have_link("Continue to the live form’s details", href: live_form_path(1))
    end

    it "displays form name as plain text" do
      expect(rendered).to have_css("h2", text: "Welsh form name")
      expect(rendered).to have_css("p", text: "Ffurflen 1")
      expect(rendered).not_to have_css(".govuk-summary-list")
    end

    it "displays the Form URL heading and button text" do
      expect(rendered).to have_css("h2", text: t("make_live.confirmation.welsh_form_url"))
      expect(rendered).to have_css("[data-copy-button-text='#{t('make_live.confirmation.copy_welsh_url_to_clipboard')}']")
    end
  end
end
