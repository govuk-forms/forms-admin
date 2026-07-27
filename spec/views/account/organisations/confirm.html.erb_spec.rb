require "rails_helper"

describe "account/organisations/confirm.html.erb" do
  let(:confirm_organisation_input) { Account::ConfirmOrganisationInput.new(organisation: organisation) }
  let(:organisation) { build_stubbed(:organisation, name: "Department for Testing", abbreviation: "DOT") }

  before do
    assign(:confirm_organisation_input, confirm_organisation_input)
  end

  context "when there are no errors" do
    before do
      render
    end

    it "sets the page title" do
      expect(view.content_for(:title)).to eq(t("page_titles.confirm_account_organisation"))
    end

    it "displays the organisation name in the paragraph text" do
      expect(rendered).to have_content("we think your organisation is Department for Testing (DOT)")
    end

    it "displays the form" do
      expect(rendered).to have_selector('form[action="/account/organisation/confirm"][method="post"]')
      expect(rendered).to have_button(I18n.t("save_and_continue"))
    end

    it "has the expected radios legend" do
      expect(rendered).to have_selector("legend", text: "Do you work for Department for Testing (DOT)?")
    end

    it "renders yes and no radio buttons" do
      expect(rendered).to have_selector('input[type="radio"][value="yes"]')
      expect(rendered).to have_selector('input[type="radio"][value="no"]')
    end

    it "has the expected labels for the radio buttons" do
      expect(rendered).to have_selector('label[for="account-confirm-organisation-input-confirm-yes-field"]', text: "Yes")
      expect(rendered).to have_selector('label[for="account-confirm-organisation-input-confirm-no-field"]', text: "No, I work for a different organisation")
    end
  end

  context "when there are errors" do
    before do
      confirm_organisation_input.errors.add(:base, "Some error")
      render
    end

    it "displays the error summary" do
      expect(rendered).to have_selector(".govuk-error-summary")
    end

    it "sets the page title with error prefix" do
      expect(view.content_for(:title)).to eq(title_with_error_prefix(t("page_titles.confirm_account_organisation"), true))
    end
  end
end
