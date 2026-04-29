require "rails_helper"

describe "routes/show.html.erb" do
  let(:form) { build_stubbed :form }

  def render_page
    assign(:current_form, form)
    render template: "routes/show", locals: { current_form: form }
  end

  it "has the correct title" do
    render_page
    expect(view.content_for(:title)).to have_content("Edit question routes")
  end

  it "has the correct back link" do
    render_page
    expect(view.content_for(:back_link)).to have_link("Back to your form", href: form_pages_path(form.id))
  end

  it "has the correct heading and caption" do
    render_page
    expect(rendered).to have_selector("h1", text: form.name)
    expect(rendered).to have_selector("h1", text: "Edit question routes")
  end
end
