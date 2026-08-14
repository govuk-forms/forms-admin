require "rails_helper"

RSpec.describe "pages/exit_pages/delete" do
  let(:delete_confirmation_input) { Forms::DeleteConfirmationInput.new }
  let(:current_form) { create :form }
  let(:page) { create :page, form: current_form }
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
end
