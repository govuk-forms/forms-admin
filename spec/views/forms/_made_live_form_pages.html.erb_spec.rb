require "rails_helper"

describe "forms/_made_live_form_pages.html.erb" do
  let(:form) { create :form, :ready_for_live }
  let(:form_document) { FormDocument::Content.from_form_document(form.latest_form_document) }
  let(:welsh_form_document) { nil }
  let(:status) { :live }
  let(:show_form_path) { Faker::Internet.url }
  let(:multiple_branches_enabled) { false }

  before do
    create :exit_page, question_page: form.pages.first, heading: "You are not eligible", markdown: "Because we say so"
    create :exit_page, question_page: form.pages.first

    form.set_task_status_service(TaskStatusService.new(form:))
    form.make_live!
    form.reload

    render(partial: "forms/made_live_form_pages", locals: {
      form_document:,
      welsh_form_document:,
      status:,
      show_form_path:,
      multiple_branches_enabled:,
    })
  end

  it "renders the made_live_form_pages partial" do
    expect(rendered).to render_template(partial: "forms/_made_live_form_pages")
  end

  it "form name is in the page title" do
    expect(view.content_for(:title)).to have_content(form_document.name)
  end

  it "has correct page heading" do
    expect(rendered).to have_css("h1", text: "#{form_document.name} - Your questions", exact_text: true, normalize_ws: true)
  end

  it "does not render the exit pages section heading" do
    expect(rendered).not_to have_css("h3", text: I18n.t("step_summary_card.exit_page.section_heading", question_number: 1, count: 1))
  end

  context "when multiple_branches_enabled is true and a page has exit pages" do
    let(:multiple_branches_enabled) { true }

    it "renders the exit pages section heading" do
      expect(rendered).to have_css("h3", text: I18n.t("step_summary_card.exit_page.section_heading", question_number: 1, count: 2))
    end

    it "renders a numbered heading for each exit page" do
      expect(rendered).to have_css("h4", text: I18n.t("step_summary_card.exit_page.number", exit_page_number: 1))
      expect(rendered).to have_css("h4", text: I18n.t("step_summary_card.exit_page.number", exit_page_number: 2))
    end

    it "renders the exit page heading values" do
      expect(rendered).to have_content("You are not eligible")
      expect(rendered).to have_content("Because we say so")
    end
  end
end
