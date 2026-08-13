require "rails_helper"

describe "forms/live/show_pages.html.erb" do
  let(:form) { create :form, :live }
  let(:form_document) { FormDocument::Content.from_form_document(form.latest_form_document) }
  let(:welsh_form_document) { nil }
  let(:multiple_branches_enabled) { false }

  before do
    render(template: "forms/live/show_pages", locals: { form_document:, welsh_form_document:, multiple_branches_enabled: })
  end

  it "renders the made_live_form_pages partial" do
    expect(rendered).to render_template(partial: "forms/_made_live_form_pages")
  end

  it "back link is set to the path to show a live form" do
    expect(rendered).to have_link("Back to your form", href: "/forms/#{form_document.id}/live")
  end

  it "rendered live tag" do
    expect(rendered).to have_css(".govuk-tag.govuk-tag--teal", text: "Live")
  end
end
