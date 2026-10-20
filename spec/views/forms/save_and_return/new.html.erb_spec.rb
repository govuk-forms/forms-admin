require "rails_helper"

describe "forms/save_and_return/new.html.erb" do
  let(:form) { build(:form, id: 1, save_and_return:, state:) }
  let(:save_and_return) { "enabled" }
  let(:state) { :draft }
  let(:save_and_return_input) { Forms::SaveAndReturnInput.new(form:).assign_form_values }

  before do
    assign(:save_and_return_input, save_and_return_input)
    render
  end

  it "sets the page title" do
    expect(view.content_for(:title)).to eq(t("page_titles.save_and_return"))
  end

  it "has the correct heading" do
    expect(rendered).to have_css("h1", text: t("page_titles.save_and_return"))
  end

  it "includes the expected body text" do
    expect(rendered).to include(t("forms.save_and_return.new.body_html"))
  end

  it "includes the expected fieldset legend" do
    expect(rendered).to have_css("legend", text: "Do you want to give people the option to save their progress?")
  end

  it "includes the expected hint text" do
    expect(rendered).to have_css("div.govuk-hint", text: t("forms.save_and_return.new.hint_text"))
  end

  it "has a checkbox with a checked value of enabled" do
    expect(rendered).to have_css("input[type='checkbox'][name='forms_save_and_return_input[save_and_return]'][value='enabled']")
  end

  it "has a hidden input with a value of disabled, used when the checkbox isn't checked" do
    expect(rendered).to have_css("input[name='forms_save_and_return_input[save_and_return]'][value='disabled']", visible: :hidden)
  end

  it "includes the expected checkbox label" do
    expect(rendered).to have_css(".govuk-label[for='forms-save-and-return-input-save-and-return-enabled-field']", text: "Give people the option to save their progress and return later")
  end

  context "when the form has save_and_return set to 'enabled'" do
    let(:save_and_return) { "enabled" }

    it "renders the checkbox as checked" do
      expect(rendered).to have_checked_field("forms-save-and-return-input-save-and-return-enabled-field")
    end
  end

  context "when the form has save_and_return set to 'disabled'" do
    let(:save_and_return) { "disabled" }

    it "renders the checkboxes as unchecked" do
      expect(rendered).to have_unchecked_field("forms-save-and-return-input-save-and-return-enabled-field")
    end
  end

  context "when the form is live with draft and save and return is enabled" do
    let(:state) { :live_with_draft }

    it "renders the checked checkbox as disabled" do
      expect(rendered).to have_field("forms-save-and-return-input-save-and-return-enabled-field", checked: true, disabled: true)
    end
  end

  context "when the form is live with draft and save and return is disabled" do
    let(:state) { :live_with_draft }
    let(:save_and_return) { "disabled" }

    it "renders the checkbox as unchecked and enabled" do
      expect(rendered).to have_field("forms-save-and-return-input-save-and-return-enabled-field", checked: false, disabled: false)
    end
  end

  context "when the form is live and save and return is enabled" do
    let(:state) { :live }

    it "renders the checkbox as checked and disabled" do
      expect(rendered).to have_field("forms-save-and-return-input-save-and-return-enabled-field", checked: true, disabled: true)
    end
  end
end
