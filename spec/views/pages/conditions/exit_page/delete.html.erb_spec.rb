require "rails_helper"

describe "conditions/exit_page/delete.html.erb" do
  let(:form) { create :form }
  let(:pages) do
    build_list(:page, 3) do |page, i|
      page.id = i + 1
    end
  end
  let(:exit_page_input) { Pages::DeleteExitPageInput.new }
  let(:exit_page) { build :condition, :with_exit_page, id: 1 }

  before do
    assign(:current_form, form)
    assign(:page, pages.first)
    assign(:exit_page, exit_page)
    assign(:delete_exit_page_input, exit_page_input)

    render template: "conditions/exit_page/delete"
  end

  it "sets the correct title" do
    expect(view.content_for(:title)).to eq "Are you sure you want to delete this exit page?"
  end

  it "contains page heading and sub-heading" do
    expect(rendered).to have_css(".govuk-caption-l", text: exit_page.exit_page_heading)
    expect(rendered).to have_css("h1", text: "Are you sure you want to delete this exit page?")
  end

  it "has a submit button" do
    expect(rendered).to have_css("button[type='submit'].govuk-button", text: I18n.t("save_and_continue"))
  end
end
