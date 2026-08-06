require "rails_helper"

describe "pages/exit_page/new.html.erb" do
  let(:form) { create :form, :ready_for_routing }
  let(:pages) { form.pages }
  let(:exit_page_input) { Conditions::ExitPageInput.new(form:, page: pages.first, answer_value: "Option 1") }

  before do
    render template: "conditions/exit_page/new", locals: { exit_page_input:, preview_html: "Preview HTML", check_preview_validation: "true" }
  end

  it "sets the correct title" do
    expect(view.content_for(:title)).to eq "Add exit page"
  end

  it "contains page heading and sub-heading" do
    expect(rendered).to have_css("h1 .govuk-caption-l", text: "Question #{pages.first.position}’s routes")
    expect(rendered).to have_css("h1.govuk-heading-l", text: "Add exit page")
  end

  it "has a submit button" do
    expect(rendered).to have_css("button[type='submit'].govuk-button", text: I18n.t("save_and_continue"))
  end
end
