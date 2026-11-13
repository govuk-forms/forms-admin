require "rails_helper"

describe "pages/conditions/new.html.erb" do
  let(:form) { create :form, :ready_for_routing }
  let(:group) { build :group }
  let(:pages) { form.pages }
  let(:condition_input) { Pages::ConditionsInput.new(form:, page: pages.first) }

  before do
    pages.first.position = 1
    allow(view).to receive(:set_routing_page_path).with(routing_page_id: condition_input.page.id).and_return("/forms/1/new-condition?routing-page_id=#{condition_input.page.id}")
    allow(view).to receive_messages(form_pages_path: "/forms/1/pages", routing_page_path: "/forms/1/new-condition", create_condition_path: "/forms/1/pages/1/conditions/new")
    allow(form).to receive_messages(group: group, qualifying_route_pages: pages)

    render template: "pages/conditions/new", locals: { condition_input: }
  end

  it "sets the correct title" do
    expect(view.content_for(:title)).to eq "Add route 1: select an answer and where to skip to"
  end

  it "contains page heading and sub-heading" do
    expect(rendered).to have_css("h1 .govuk-caption-l", text: "Question 1’s routes")
    expect(rendered).to have_css("h1.govuk-heading-l", text: "Add route 1")
  end

  it "has a submit button" do
    expect(rendered).to have_css("button[type='submit'].govuk-button", text: I18n.t("save_and_continue"))
  end
end
