require "rails_helper"

describe "forms/make_live/confirmation.html.erb" do
  let(:has_welsh_translation) { false }
  let(:current_form) { OpenStruct.new(id: 1, name: "Form 1", name_cy: "Ffurflen 1", form_slug: "form-1", has_welsh_translation?: has_welsh_translation) }

  before do
    render template: "forms/make_live/confirmation", locals: { current_form:, confirmation_page_title: "Your form is live", confirmation_page_body: I18n.t("make_changes_live.confirmation.body_html").html_safe }
  end

  it "contains a confirmation panel with a title" do
    expect(rendered).to have_css(".govuk-panel--confirmation h1", text: /Your form is live/)
  end

  it "contains the URL of the live form" do
    expect(rendered).to have_text("runner-host/form/1/form-1")
  end

  it "contains a link to the live form details" do
    expect(rendered).to have_link("Continue to the live form’s details", href: live_form_path(1))
  end

  context "when the form has a Welsh translation" do
    let(:has_welsh_translation) { true }

    it "displays form names in a summary list" do
      expect(rendered).to have_css(".govuk-summary-list__key", text: "English form")
      expect(rendered).to have_css(".govuk-summary-list__value", text: "Form 1")
      expect(rendered).to have_css(".govuk-summary-list__key", text: "Welsh form")
      expect(rendered).to have_css(".govuk-summary-list__value", text: "Ffurflen 1")
    end

    it "displays the English form URL with specific heading and button text" do
      expect(rendered).to have_css("h2", text: "English form URL")
      expect(rendered).to have_css("[data-copy-button-text='Copy English URL to clipboard']")
    end

    it "displays the Welsh form URL" do
      expect(rendered).to have_css("h2", text: "Welsh form URL")
      expect(rendered).to have_text("runner-host/form/1/form-1.cy")
      expect(rendered).to have_css("[data-copy-button-text='Copy Welsh URL to clipboard']")
    end
  end

  context "when the form does not have a Welsh translation" do
    let(:has_welsh_translation) { false }

    it "displays form name as plain text" do
      expect(rendered).to have_css("h2", text: "Form name")
      expect(rendered).to have_css("p", text: "Form 1")
      expect(rendered).not_to have_css(".govuk-summary-list")
    end

    it "does not display the Welsh form URL" do
      expect(rendered).not_to have_css("h2", text: "Welsh form URL")
    end

    it "displays the default Form URL heading and button text" do
      expect(rendered).to have_css("h2", text: "Form URL")
      expect(rendered).to have_css("[data-copy-button-text='Copy URL to clipboard']")
    end
  end
end
