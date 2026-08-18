require "rails_helper"

describe "forms/_made_live_form_pages.html.erb" do
  let(:form) { create :form, :live }
  let(:form_document) { FormDocument::Content.from_form_document(form.latest_form_document) }
  let(:welsh_form_document) { nil }
  let(:status) { :live }
  let(:show_form_path) { Faker::Internet.url }
  let(:multiple_branches_enabled) { false }

  before do
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
end
