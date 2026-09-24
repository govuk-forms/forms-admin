require "rails_helper"

describe "forms/payment_link/new.html.erb" do
  let(:current_form) { OpenStruct.new(id: 1, name: "Form 1", form_slug: "form-1") }
  let(:payment_link_input) { Forms::PaymentLinkInput.new(form: current_form).assign_form_values }

  before do
    assign(:payment_link_input, payment_link_input)
    allow(view).to receive_messages(form_path: "/forms/1", payment_link_path: "/forms/1/payment-link")
    render template: "forms/payment_link/new"
  end

  it "contains a top-level heading" do
    expect(rendered).to have_css("h1", text: I18n.t("payment_link_input.heading"))
  end

  it "has a heading caption with the form name" do
    expect(rendered).to have_css("h1 .govuk-caption-l", text: "Form 1")
  end

  it "contains the introductory paragraph" do
    expect(rendered).to include(I18n.t("payment_link_input.body_html"))
  end

  it "contains information about setting up GOV.UK Pay" do
    expect(rendered).to have_css("h2", text: I18n.t("payment_link_input.setting_up_govuk_pay.heading"))
    expect(rendered).to include(I18n.t("payment_link_input.setting_up_govuk_pay.body_html"))
  end

  it "contains information about creating your payment link" do
    expect(rendered).to have_css("h2", text: I18n.t("payment_link_input.creating_your_payment_link.heading"))
    expect(rendered).to include(I18n.t("payment_link_input.creating_your_payment_link.body_html"))
  end

  it "contains information about setting up your payment link with a reference number" do
    expect(rendered).to have_css("h3", text: I18n.t("payment_link_input.set_up_your_payment_link.heading"))
    expect(rendered).to include(I18n.t("payment_link_input.set_up_your_payment_link.body_html"))
  end

  it "contains information about how this helps processors" do
    expect(rendered).to have_css("h3", text: I18n.t("payment_link_input.how_this_will_help_processors.heading"))
    expect(rendered).to include(I18n.t("payment_link_input.how_this_will_help_processors.body_html"))
  end

  it "contains information about how this appears to form fillers" do
    expect(rendered).to have_css("h2", text: I18n.t("payment_link_input.how_this_will_work.heading"))
    expect(rendered).to include(I18n.t("payment_link_input.how_this_will_work.body_html"))
  end

  it "includes a form field for entering your link" do
    expect(rendered).to have_field(I18n.t("helpers.label.forms_payment_link_input.payment_url"))
  end
end
