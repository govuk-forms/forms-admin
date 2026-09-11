require "rails_helper"

RSpec.describe "pages/exit_pages/delete" do
  let(:delete_confirmation_input) { Forms::DeleteConfirmationInput.new }
  let(:current_form) { create :form, :ready_for_routing }
  let(:page) { current_form.pages.first }
  let(:exit_page) { create :exit_page, question_page: page, heading: "the heading" }

  before do
    assign(:current_form, current_form)
    render locals: { page:, exit_page:, delete_confirmation_input: }
  end

  it "has a page title" do
    expect(view.content_for(:title)).to include "Are you sure you want to delete this exit page?"
  end

  it "has a heading" do
    expect(rendered).to have_css "h1", text: "Are you sure you want to delete this exit page?"
  end

  it "has a heading caption with the question text" do
    expect(rendered).to have_css ".govuk-caption-l", text: "Exit page 1: the heading"
  end

  it "has a back link to the edit exit page" do
    expect(view.content_for(:back_link)).to have_link("Back to edit exit page", href: edit_exit_page_path(form_id: current_form.id, page_id: page.id, id: exit_page.id))
  end

  it "has a delete confirmation input to confirm deletion of the page" do
    expect(rendered).to render_template "input_objects/_delete_confirmation_input"
  end

  describe "delete confirmation input" do
    it "posts to the destroy action" do
      expect(rendered).to have_element "form", action: "/forms/#{current_form.id}/pages/#{page.id}/exit-pages/#{exit_page.id}", method: "post"
    end

    it "does not have a hint" do
      expect(rendered).not_to have_css ".govuk-hint"
    end
  end

  context "when there are no routes to the exit page" do
    it "does not have a notification banner" do
      expect(rendered).not_to have_selector(".govuk-notification-banner")
    end
  end

  context "when there is a route to the exit page" do
    let(:exit_page) do
      exit_page = super()
      exit_page.conditions << create(:condition, routing_page: page, check_page: page, answer_value: "Option 1")
      exit_page
    end

    it "has a notification banner with a warning message" do
      expect(rendered).to have_selector(
        ".govuk-notification-banner__content",
        text: I18n.t("pages.exit_pages.delete.warnings.routes_will_be_deleted", routes: "route"),
      )
    end

    context "and there is a validation error" do
      let(:delete_confirmation_input) do
        delete_confirmation_input = super()
        delete_confirmation_input.validate
        delete_confirmation_input
      end

      it "does not have a notification banner" do
        expect(rendered).not_to have_selector(".govuk-notification-banner")
      end
    end
  end

  context "when there is more than one route to the exit page" do
    let(:exit_page) do
      exit_page = super()
      exit_page.conditions << [
        create(:condition, routing_page: page, check_page: page, answer_value: "Option 1"),
        create(:condition, routing_page: page, check_page: page, answer_value: "Option 2"),
      ]
      exit_page
    end

    it "has a notification banner with a warning message" do
      expect(rendered).to have_selector(
        ".govuk-notification-banner__content",
        text: I18n.t("pages.exit_pages.delete.warnings.routes_will_be_deleted", routes: "routes"),
      )
    end

    context "and there is a validation error" do
      let(:delete_confirmation_input) do
        delete_confirmation_input = super()
        delete_confirmation_input.validate
        delete_confirmation_input
      end

      it "does not have a notification banner" do
        expect(rendered).not_to have_selector(".govuk-notification-banner")
      end
    end
  end
end
