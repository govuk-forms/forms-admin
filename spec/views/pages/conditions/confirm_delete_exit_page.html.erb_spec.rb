require "rails_helper"

describe "pages/conditions/confirm_delete_exit_page.html.erb" do
  let(:form) { create :form, pages: [page] }
  let(:page) { build :page, id: 1, form_id: 1, position: 1 }
  let(:exit_page_input) { Conditions::DeleteExitPageInput.new }
  let(:exit_page) { build :condition, :with_exit_page, id: 1 }

  before do
    assign(:current_form, form)
    assign(:page, page)

    render template: "pages/conditions/confirm_delete_exit_page", locals: {
      answer_value: "answer",
      goto_page_id: 1,
      exit_page: exit_page,
      delete_exit_page_input: exit_page_input,
    }
  end

  it "sets the correct title" do
    expect(view.content_for(:title)).to eq "Your exit page will be deleted"
  end

  it "contains page heading and sub-heading" do
    expect(rendered).to have_css("h1 .govuk-caption-l", text: "Question 1’s routes")
    expect(rendered).to have_css("h1.govuk-heading-l", text: "Your exit page will be deleted")
  end

  it "has a submit button" do
    expect(rendered).to have_css("button[type='submit'].govuk-button", text: I18n.t("save_and_continue"))
  end
end
