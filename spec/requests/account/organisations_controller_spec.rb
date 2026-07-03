require "rails_helper"

describe Account::OrganisationsController do
  let(:domain) { "example.gov.uk" }
  let(:user) { create(:user, :with_no_org, email: Faker::Internet.email(domain: domain)) }

  before do
    login_as user
  end

  describe "GET #edit" do
    context "when the user does not have an organisation" do
      it "renders the edit template" do
        get edit_account_organisation_path
        expect(response).to render_template(:edit)
      end

      context "when the show_relevant_organisations feature is enabled", :feature_show_relevant_organisations do
        it "assign the input object with allowed organisations limited by the user's domain" do
          matching_orgs = [
            create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)]),
            create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)]),
          ]
          create(:organisation, organisation_domains: [create(:organisation_domain, domain: "example.com")])
          create(:organisation, closed: true, organisation_domains: [create(:organisation_domain, domain: domain)])

          get edit_account_organisation_path

          input_object = assigns(:organisation_input)
          expect(input_object).to be_a(Account::OrganisationInput)
          expect(input_object.allowed_organisations).to match_array(matching_orgs)
        end
      end

      context "when the show_relevant_organisations feature is disabled", feature_show_relevant_organisations: false do
        it "assigns the input object with all not closed organisations" do
          orgs = create_list(:organisation, 2)
          create(:organisation, closed: true)

          get edit_account_organisation_path

          input_object = assigns(:organisation_input)
          expect(input_object).to be_a(Account::OrganisationInput)
          expect(input_object.allowed_organisations).to match_array(orgs)
        end
      end
    end

    context "when the user already has an organisation" do
      let(:user) { create(:user) }

      it "redirects to the root path" do
        get edit_account_organisation_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PUT #update" do
    context "with valid parameters" do
      let(:organisation) { create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)]) }
      let(:valid_params) { { account_organisation_input: { organisation_id: organisation.id } } }

      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(AfterSignInPathHelper).to receive(:after_sign_in_next_path).and_return("/next-path")
        # rubocop:enable RSpec/AnyInstance
      end

      it "updates the user's organisation" do
        put account_organisation_path, params: valid_params
        expect(user.reload.organisation).to eq(organisation)
      end

      it "redirects to the root path" do
        put account_organisation_path, params: valid_params
        expect(response).to redirect_to("/next-path")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) { { account_organisation_input: { organisation_id: nil } } }

      it "does not update the user's organisation" do
        expect {
          put account_organisation_path, params: invalid_params
        }.not_to(change { user.reload.organisation })
      end

      it "re-renders the edit template" do
        put account_organisation_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:edit)
      end
    end

    context "when the show_relevant_organisations feature is enabled", :feature_show_relevant_organisations do
      context "when the selected organisation does not match the user's email domain" do
        let(:organisation) { create(:organisation, organisation_domains: [create(:organisation_domain, domain: "other.gov.uk")]) }
        let(:invalid_params) { { account_organisation_input: { organisation_id: organisation.id } } }

        it "does not update the user's organisation" do
          expect {
            put account_organisation_path, params: invalid_params
          }.not_to(change { user.reload.organisation })
        end

        it "re-renders the edit template" do
          put account_organisation_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_content)
          expect(response).to render_template(:edit)
        end
      end
    end

    context "when the show_relevant_organisations feature is disabled", feature_show_relevant_organisations: false do
      context "when the selected organisation does not match the user's email domain" do
        let(:organisation) { create(:organisation, organisation_domains: [create(:organisation_domain, domain: "other.gov.uk")]) }
        let(:params) { { account_organisation_input: { organisation_id: organisation.id } } }

        it "updates the user's organisation" do
          put account_organisation_path, params: params
          expect(user.reload.organisation).to eq(organisation)
        end
      end
    end
  end
end
