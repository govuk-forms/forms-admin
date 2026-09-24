require "rails_helper"

describe "forms/privacy_policy/new.html.erb" do
  let(:current_form) { OpenStruct.new(id: 1, name: "Form 1", privacy_policy_url: nil) }
  let(:privacy_policy_input) { Forms::PrivacyPolicyInput.new(form: current_form).assign_form_values }

  before do
    assign(:privacy_policy_input, privacy_policy_input)
    allow(view).to receive_messages(form_path: "/forms/1", privacy_policy_path: "/forms/1/privacy-policy")
    render template: "forms/privacy_policy/new"
  end

  it "contains a top-level heading" do
    expect(rendered).to have_css("h1", text: I18n.t("privacy_policy_input.heading"))
  end

  it "has a heading caption with the form name" do
    expect(rendered).to have_css("h1 .govuk-caption-l", text: "Form 1")
  end
end
