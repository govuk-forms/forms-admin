require "rails_helper"

describe "exit_pages/new.html.erb" do
  let(:form) { build_stubbed :form, :with_pages, pages: [build_stubbed(:page, id: 1)] }
  let(:page) { form.pages.first }
  let(:exit_page_input) { Pages::ExitPageInput.new(page:) }

  def render_page
    assign(:current_form, form)
    render template: "pages/exit_pages/new", locals: { exit_page_input:, preview_html: "", check_preview_validation: false }
  end

  it "has the correct title" do
    render_page
    expect(view.content_for(:title)).to have_content("Add exit page")
  end

  it "has the correct back link" do
    render_page
    expect(view.content_for(:back_link)).to have_link("Back to edit question routes", href: routes_path(form.id))
  end

  it "has the correct heading and caption" do
    render_page
    expect(rendered).to have_selector "h1", text: "Question 1’s exit pages"
    expect(rendered).to have_selector "h1", text: "Add exit page"
  end

  it "shows the page title as a summary list" do
    render_page
    expect(rendered).to have_css(".govuk-summary-list__key", text: "Question #{page.position}")
    expect(rendered).to have_css(".govuk-summary-list__value", text: page.question_text)
  end

  it "shows error messages" do
    exit_page_input.errors.add(:heading, "Error: Heading can't be blank")
    render_page
    expect(rendered).to have_text("Error: Heading can't be blank")
  end
end
