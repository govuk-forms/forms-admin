require "rails_helper"

describe "forms/what_happens_next/new.html.erb" do
  let(:current_form) { create :form }
  let(:group) { create(:group) }
  let(:what_happens_next_input) { Forms::WhatHappensNextInput.new(form: current_form).assign_form_values }
  let(:preview_html) { "" }

  before do
    GroupForm.create!(form_id: current_form.id, group_id: group.id)
    assign(:what_happens_next_input, what_happens_next_input)
    assign(:preview_html, preview_html)
    render template: "forms/what_happens_next/new", locals: { current_form: }
  end

  it "contains an example" do
    expect(rendered).to have_text(I18n.t("what_happens_next.example.heading"))
    expect(rendered).to have_text(I18n.t("what_happens_next.example.body"))
  end

  it "contains instructions" do
    expect(rendered).to have_text(I18n.t("what_happens_next.instructions"))
  end

  it "contains text about how the content is used" do
    expect(rendered).to include(I18n.t("what_happens_next.how_this_content_is_used_html"))
  end

  it "contains text about reference numbers" do
    expect(rendered).to have_text(I18n.t("what_happens_next.reference_numbers"))
  end

  it "has content saying that answers might be included in the confirmation email" do
    expect(rendered).to have_text(I18n.t("what_happens_next.confirmation_email"))
  end
end
