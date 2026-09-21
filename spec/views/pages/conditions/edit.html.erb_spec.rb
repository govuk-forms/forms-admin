require "rails_helper"

describe "pages/conditions/edit.html.erb" do
  let(:condition_input) { Pages::ConditionsInput.new(form:, page:, record: condition) }
  let(:form) { create :form, :ready_for_routing }
  let(:group) { build :group }
  let(:pages) { form.pages }
  let(:page) { pages.first }
  let(:condition) { create :condition, routing_page_id: page.id, check_page_id: page.id, answer_value: "Option 1", goto_page_id: pages.third.id }
  let(:secondary_skip) { false }

  before do
    pages.each(&:reload)
    page.position = 1
    allow(form).to receive_messages(group: group, qualifying_route_pages: pages)
    allow(condition_input).to receive(:secondary_skip?).and_return(secondary_skip)
    condition_input.check_errors_from_api

    render template: "pages/conditions/edit", locals: { condition_input: }
  end

  it "sets the correct title" do
    expect(view.content_for(:title)).to eq("Edit route 1")
  end

  it "contains page heading and sub-heading" do
    expect(rendered).to have_css("h1 .govuk-caption-l", text: "Question 1’s routes")
    expect(rendered).to have_css("h1.govuk-heading-l", text: "Edit route 1")
  end

  it "does not contain a change action for editing the question of the route" do
    expect(rendered).not_to have_css(".govuk-summary-list__row .govuk-summary-list__actions")
  end

  it "has a submit button" do
    expect(rendered).to have_css("button[type='submit'].govuk-button", text: I18n.t("save_and_continue"))
  end

  it "has a delete route link" do
    expect(rendered).to have_link(text: "Delete route", href: "/forms/#{form.id}/pages/#{page.id}/conditions/#{condition.id}/delete")
  end

  context "with a validation error" do
    let(:condition) { create :condition, routing_page_id: page.id, check_page_id: page.id, goto_page_id: pages.third.id, answer_value: "Invalid option" }

    it "has an error link that matches the field with errors" do
      field_id = "pages-conditions-input-answer-value-field-error"

      expect(rendered).to have_css(".govuk-error-summary")
      expect(rendered).to have_link(I18n.t("activemodel.errors.models.pages/conditions_input.attributes.answer_value.answer_value_doesnt_exist", href: "##{field_id}"))
      expect(rendered).to have_css("##{field_id}")
    end
  end

  context "when the condition does not have an exit page" do
    it "has an 'add exit page' option" do
      expect(rendered).to have_content("Add an exit page")
    end
  end

  context "when the condition has an exit page" do
    let(:condition) { create :condition, :with_exit_page, routing_page_id: page.id, check_page_id: page.id, answer_value: "Option 1" }

    it "has the exit page heading" do
      expect(rendered).to have_content(condition.exit_page_heading)
    end
  end

  context "when the page already has a secondary skip route" do
    let(:secondary_skip) { true }

    it "does not have an 'add exit page' option" do
      expect(rendered).not_to have_content("Add an exit page")
    end
  end
end
