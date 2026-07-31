require "rails_helper"

describe "account/organisations/edit.html.erb" do
  let(:organisation_input) { Account::OrganisationInput.new(allowed_organisations: organisations, user:) }
  let(:contact_href) { "https://example.com/contact" }
  let(:user) { build(:user, email: "user@example.com") }
  let(:organisations) do
    [
      build_stubbed(:organisation, slug: "test-org"),
      build_stubbed(:organisation, slug: "department-for-testing", name: "Department for Testing"),
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

    it "sets the page title" do
      expect(view.content_for(:title)).to eq(t("page_titles.account_organisation"))
    end

    it "displays the form" do
      expect(rendered).to have_selector('form[action="/account/organisation"][method="post"]')
      expect(rendered).to have_field("_method", with: "patch", type: :hidden)
      expect(rendered).to have_button(I18n.t("save_and_continue"))
    end

    context "when the show_relevant_organisations feature is disabled", feature_show_relevant_organisations: false do
      it "has the expected h1" do
        expect(rendered).to have_selector("h1", text: "Select your organisation")
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
    end

    context "when the show_relevant_organisations feature is enabled", :feature_show_relevant_organisations do
      it "has the expected h1" do
        expect(rendered).to have_selector("h1", text: t("page_titles.account_organisation"))
      end

      it "displays the user's email domain" do
        expect(rendered).to have_content(I18n.t("account.organisations.edit.you_created_account_with", email_domain: "example.com"))
      end

      context "when there are fewer than 30 organisations" do
        it "has the expected h2" do
          expect(rendered).to have_selector("h2", text: "Which of these organisations do you work for?")
        end

        it "renders the organisation radio buttons" do
          expect(rendered).to have_selector('input[type="radio"][name="account_organisation_input[organisation_id]"]', count: organisations.size + 1)
          organisations.each do |organisation|
            expect(rendered).to have_selector("label[for='account-organisation-input-organisation-id-#{organisation.id}-field']", text: organisation.name_with_abbreviation)
          end
        end

        it "has a divider" do
          expect(rendered).to have_selector(".govuk-radios__divider", text: "or")
        end

        it "has a radio button for organisation not listed" do
          expect(rendered).to have_selector("input[type='radio'][value='not_listed'][name='account_organisation_input[organisation_id]']")
          expect(rendered).to have_selector("label[for='account-organisation-input-organisation-id-not-listed-field']", text: I18n.t("account.organisations.edit.not_listed_option"))
        end

        it "does not render the not listed details component" do
          expect(rendered).not_to have_selector("details.govuk-details")
        end
      end

      context "when there are more than 30 organisations" do
        let(:organisations) { build_stubbed_list(:organisation, 31) }

        it "has the expected h2" do
          expect(rendered).to have_selector("h2", text: "Which of these organisations do you work for?")
        end

        it "renders the organisation select field for autocomplete" do
          expect(rendered).to have_selector('select[name="account_organisation_input[organisation_id]"]', visible: :all)
          organisations.each do |organisation|
            expect(rendered).to have_selector("option[value='#{organisation.id}']", text: organisation.name)
          end
        end

        it "has organisation fields with abbreviations" do
          expect(rendered).to have_select(
            "Which of these organisations do you work for?",
            with_options: organisations.map(&:name_with_abbreviation),
          )
        end

        it "renders the not listed details component" do
          expect(rendered).to have_selector("details.govuk-details")
          expect(rendered).to have_selector("summary.govuk-details__summary", text: I18n.t("account.organisations.edit.details_summary"))
        end
      end
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
end
