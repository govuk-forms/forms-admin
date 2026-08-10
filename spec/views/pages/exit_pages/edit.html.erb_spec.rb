require "rails_helper"

describe "exit_pages/edit.html.erb" do
  let(:form) { build_stubbed :form, :with_pages, pages: [build_stubbed(:page, id: 1)] }
  let(:page) { form.pages.first }
  let(:exit_page) { build_stubbed(:exit_page, question_page: page) }
  let(:exit_page_input) { Pages::UpdateExitPageInput.new(page:, exit_page:) }

  def render_page
    assign(:current_form, form)
    assign(:page, page)
    render template: "pages/exit_pages/edit", locals: { exit_page_input:, preview_html: "", check_preview_validation: false }
  end

  it "has the correct title" do
    render_page
    expect(view.content_for(:title)).to have_content("Edit exit page")
  end

  it "has the correct back link" do
    render_page
    expect(view.content_for(:back_link)).to have_link("Back to edit question routes", href: routes_path(form.id))
  end

  it "has the correct heading and caption" do
    render_page
    expect(rendered).to have_selector "h1", text: "Question 1’s exit pages"
    expect(rendered).to have_selector "h1", text: "Edit exit page"
  end

  it "shows the page title as a summary list" do
    render_page
    expect(rendered).to have_css(".govuk-summary-list__key", text: "Question #{page.position}")
    expect(rendered).to have_css(".govuk-summary-list__value", text: page.question_text)
  end

  context "when the exit page has no options" do
    before do
      allow(exit_page).to receive(:options_to_this_exit_page).and_return([])
    end

    it "shows the page title as a summary list" do
      render_page

      expect(rendered).to have_css(".govuk-summary-list__key", text: "Options that go to this exit page")
      expect(rendered).to have_css(".govuk-summary-list__value", text: "No route to this exit page")
    end
  end

  context "when the exit page has has a single option" do
    let(:options) { %w[option1] }

    before do
      allow(exit_page).to receive(:options_to_this_exit_page).and_return(options)
    end

    it "shows the page title as a summary list" do
      render_page

      expect(rendered).to have_css(".govuk-summary-list__key", text: "Options that go to this exit page")
      expect(rendered).to have_css(".govuk-summary-list__value:text()", text: "option1", exact: true)
    end
  end

  context "when the exit page has multiple options" do
    let(:options) { %w[option1 option2 option3] }

    before do
      allow(exit_page).to receive(:options_to_this_exit_page).and_return(options)
    end

    it "shows the page title as a summary list" do
      render_page

      expect(rendered).to have_css(".govuk-summary-list__key", text: "Options that go to this exit page")
      expect(rendered).to have_css("li", text: options.first)
      expect(rendered).to have_css("li", text: options.second)
      expect(rendered).to have_css("li", text: options.third)
    end
  end

  it "shows error messages" do
    exit_page_input.errors.add(:heading, "Error: Heading can't be blank")
    render_page
    expect(rendered).to have_text("Error: Heading can't be blank")
  end
end
