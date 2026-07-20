require "rails_helper"

describe "account/organisations/edit.html.erb" do
  let(:organisation_input) { Account::OrganisationInput.new }
  let(:contact_href) { "https://example.com/contact" }
  let!(:organisations) do
    [
      create(:organisation, slug: "test-org"),
      create(:organisation, slug: "department-for-testing", name: "Department for Testing"),
    ]
  end

  before do
    assign(:organisation_input, organisation_input)
    allow(view).to receive(:contact_link).and_return(contact_href)
  end

  context "when there are no errors" do
    before do
      render
    end

    it "displays the form" do
      expect(rendered).to have_selector('form[action="/account/organisation"][method="post"]')
      expect(rendered).to have_field("_method", with: "patch", type: :hidden)
      expect(rendered).to have_button(I18n.t("save_and_continue"))
    end

    it "renders the organisation select field for autocomplete" do
      expect(rendered).to have_selector('select[name="account_organisation_input[organisation_id]"]', visible: :all)
      organisations.each do |organisation|
        expect(rendered).to have_selector("option[value='#{organisation.id}']", text: organisation.name)
      end
    end

    it "has organisation fields with abbreviations" do
      expect(rendered).to have_select(
        "Select your organisation",
        with_options: [
          "Department for Testing (DfT)",
          "Test Org (TO)",
        ],
      )
    end

    it "sets the page title" do
      expect(view.content_for(:title)).to eq(t("page_titles.account_organisation"))
    end
  end

  context "when there are errors" do
    before do
      organisation_input.errors.add(:base, "Some error")
      render
    end

    it "displays the error summary" do
      expect(rendered).to have_selector(".govuk-error-summary")
    end

    it "sets the page title with error prefix" do
      expect(view.content_for(:title)).to eq(title_with_error_prefix(t("page_titles.account_organisation"), true))
    end
  end

  context "when there are closed organisations" do
    before do
      create(:organisation, slug: "closed-org", closed: true)

      render
    end

    it "only shows the organisations that are not closed" do
      expect(rendered).to have_select(
        "Select your organisation",
        options: [
          "Select an organisation",
          "Department for Testing (DfT)",
          "Test Org (TO)",
        ],
      )
    end
  end
end
