require "rails_helper"

describe "pages/index.html.erb" do
  let(:form) { create :form, pages: }
  let(:pages) { [] }
  let(:mark_complete_input) { Forms::MarkPagesSectionCompleteInput.new(form:).assign_form_values }

  before do
    assign(:pages, pages)
    assign(:mark_complete_input, mark_complete_input)
    render template: "pages/index", locals: { current_form: form }
  end

  it "has the correct title" do
    expect(view.content_for(:title)).to eq I18n.t("pages.index.title")
  end

  it "allows the user to add a page" do
    expect(rendered).to have_link(I18n.t("pages.index.add_question"), href: start_new_question_path(form.id))
  end

  it "has a link to branch routing page" do
    expect(rendered).to have_link("Add a question route", href: routing_page_path(form.id))
  end

  describe "when there are no pages to display" do
    it "does not contain a list of pages" do
      expect(rendered).not_to have_text I18n.t("forms.form_overview.your_questions")
      expect(rendered).not_to have_css ".govuk-summary-list"
    end
  end

  describe "when there are more than one page to display" do
    let(:pages) { [(build :page, id: 1, position: 1, form_id: 1), (build :page, id: 2, position: 2, form_id: 1), (build :page, id: 3, position: 3, form_id: 1)] }

    it "does contain a summary list entry each page" do
      expect(rendered).to have_text I18n.t("forms.form_overview.your_questions")
      expect(rendered).to have_css ".govuk-summary-list__row", count: 3
    end

    it "has a link to change the page order" do
      expect(rendered).to have_link("Change your question order", href: change_order_new_path(form.id))
    end
  end
end
