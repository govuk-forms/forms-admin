require "rails_helper"

describe Account::OrganisationsController do
  let(:domain) { "example.gov.uk" }
  let(:email) { "user@#{domain}" }

  def pending_user_organisation_id
    session[PendingUser::SESSION_KEY]["organisation_id"]
  end

  before do
    allow(Settings).to receive(:auth_provider).and_return("auth0")
  end

  context "when there is no pending user" do
    it "redirects to the root path" do
      get edit_account_organisation_path
      expect(response).to redirect_to(root_path)
    end
  end

  context "when the user does not exist yet" do
    before do
      sign_in_with_auth0(email:)
    end

    describe "GET #edit" do
      context "when there is more than one organisation the user can select" do
        it "assign the input object with allowed organisations limited by the user's domain" do
          matching_orgs = [
            create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)]),
            create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)]),
          ]
          create(:organisation, organisation_domains: [create(:organisation_domain, domain: "example.com")])
          create(:organisation, closed: true, organisation_domains: [create(:organisation_domain, domain: domain)])

          get edit_account_organisation_path

          expect(response).to render_template(:edit)

          input_object = assigns(:organisation_input)
          expect(input_object).to be_a(Account::OrganisationInput)
          expect(input_object.allowed_organisations).to match_array(matching_orgs)
        end
      end

      context "when there are no organisations the user can select" do
        it "renders the no_matches template" do
          get edit_account_organisation_path
          expect(response).to render_template(:no_matches)
        end
      end

      context "when there is only one organisation the user can select" do
        it "redirects to the confirm organisation path" do
          create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)])

          get edit_account_organisation_path
          expect(response).to redirect_to(show_confirm_account_organisation_path)
        end
      end
    end

    describe "PUT #update" do
      context "with valid parameters" do
        let(:organisation) { create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)]) }
        let(:valid_params) { { account_organisation_input: { organisation_id: organisation.id } } }

        it "stores the organisation in the session without creating the user" do
          expect {
            put account_organisation_path, params: valid_params
          }.not_to change(User, :count)

          expect(pending_user_organisation_id).to eq(organisation.id.to_s)
        end

        it "redirects to the name page" do
          put account_organisation_path, params: valid_params
          expect(response).to redirect_to(edit_account_name_path)
        end

        context "when the name has already been entered" do
          before do
            put account_name_path, params: { account_name_input: { name: "John Doe" } }
          end

          it "creates the user and signs them in" do
            expect {
              put account_organisation_path, params: valid_params
            }.to change(User, :count).by(1)

            user = User.find_by(email:)
            expect(user.organisation).to eq(organisation)
            expect(request.env["warden"].user).to eq user
            expect(session[PendingUser::SESSION_KEY]).to be_nil
          end

          it "redirects to the next account setup page" do
            put account_organisation_path, params: valid_params
            expect(response).to redirect_to(edit_account_terms_of_use_path)
          end
        end
      end

      context "when the not listed radio option is selected" do
        let(:params) { { account_organisation_input: { organisation_id: Account::OrganisationInput::NOT_LISTED_OPTION_VALUE } } }

        before do
          create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)])
        end

        it "renders the no_matches template" do
          put account_organisation_path, params: params
          expect(response).to render_template(:no_matches)
        end

        it "does not store the organisation" do
          put account_organisation_path, params: params
          expect(pending_user_organisation_id).to be_nil
        end
      end

      context "with invalid parameters" do
        let(:invalid_params) { { account_organisation_input: { organisation_id: nil } } }

        before do
          create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)])
        end

        it "does not store the organisation" do
          put account_organisation_path, params: invalid_params
          expect(pending_user_organisation_id).to be_nil
        end

        it "re-renders the edit template" do
          put account_organisation_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_content)
          expect(response).to render_template(:edit)
        end
      end

      context "when the selected organisation does not match the user's email domain" do
        let(:organisation) { create(:organisation, organisation_domains: [create(:organisation_domain, domain: "other.gov.uk")]) }
        let(:invalid_params) { { account_organisation_input: { organisation_id: organisation.id } } }

        before do
          create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)])
        end

        it "does not store the organisation" do
          put account_organisation_path, params: invalid_params
          expect(pending_user_organisation_id).to be_nil
        end

        it "re-renders the edit template" do
          put account_organisation_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_content)
          expect(response).to render_template(:edit)
        end
      end

      context "when there are no organisations the user can select" do
        it "renders the no_matches template" do
          put account_organisation_path, params: {}
          expect(response).to render_template(:no_matches)
        end
      end
    end

    describe "GET #show_confirm" do
      context "when there is only one organisation the user can select" do
        let!(:organisation) { create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)]) }

        it "renders the confirm template" do
          get show_confirm_account_organisation_path
          expect(response).to render_template(:confirm)

          input_object = assigns(:confirm_organisation_input)
          expect(input_object).to be_a(Account::ConfirmOrganisationInput)
          expect(input_object.organisation).to eq(organisation)
        end
      end

      context "when there are no organisations the user can select" do
        it "renders the no_matches template" do
          get show_confirm_account_organisation_path
          expect(response).to render_template(:no_matches)
        end
      end

      context "when there is more than one organisation the user can select" do
        before do
          create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)])
          create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)])
        end

        it "redirects to the edit route" do
          get show_confirm_account_organisation_path
          expect(response).to redirect_to edit_account_organisation_path
        end
      end
    end

    describe "POST #confirm" do
      let(:params) { { account_confirm_organisation_input: { confirm: "yes" } } }

      context "when there is only one organisation the user can select" do
        let!(:organisation) { create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)]) }

        context "when 'yes' is selected" do
          it "stores the organisation and redirects to the name page" do
            post confirm_account_organisation_path, params: params
            expect(pending_user_organisation_id).to eq(organisation.id)
            expect(response).to redirect_to(edit_account_name_path)
          end
        end

        context "when 'no' is selected" do
          let(:params) { { account_confirm_organisation_input: { confirm: "no" } } }

          it "renders the no_matches template and does not store the organisation" do
            post confirm_account_organisation_path, params: params
            expect(pending_user_organisation_id).to be_nil
            expect(response).to render_template(:no_matches)
          end
        end

        context "when the params are invalid" do
          let(:params) { { account_confirm_organisation_input: { confirm: "" } } }

          it "renders the confirm template with an error message" do
            post confirm_account_organisation_path, params: params
            expect(pending_user_organisation_id).to be_nil
            expect(response).to have_http_status(:unprocessable_content)
            expect(response).to render_template(:confirm)

            error = I18n.t("activemodel.errors.models.account/confirm_organisation_input.attributes.confirm.blank", organisation: organisation.name_with_abbreviation)
            expect(response.body).to include(error)
          end
        end
      end

      context "when there are no organisations the user can select" do
        it "renders the no_matches template" do
          post confirm_account_organisation_path, params: params
          expect(response).to render_template(:no_matches)
        end
      end

      context "when there is more than one organisation the user can select" do
        before do
          create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)])
          create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)])
        end

        it "redirects to the edit route" do
          post confirm_account_organisation_path, params: params
          expect(response).to redirect_to edit_account_organisation_path
        end
      end
    end
  end

  context "when the user exists but does not have an organisation" do
    let!(:user) { create(:user, :with_no_org, email:, uid: "auth0-uid", provider: "auth0") }
    let!(:organisation) { create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)]) }

    before do
      sign_in_with_auth0(email:)

      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(AfterSignInPathHelper).to receive(:after_sign_in_next_path).and_return("/next-path")
      # rubocop:enable RSpec/AnyInstance
    end

    it "redirects to the organisation page when signing in" do
      expect(response).to redirect_to(edit_account_organisation_path)
    end

    it "updates the user's organisation and signs them in" do
      post confirm_account_organisation_path, params: { account_confirm_organisation_input: { confirm: "yes" } }

      expect(user.reload.organisation).to eq(organisation)
      expect(request.env["warden"].user).to eq user
    end

    it "redirects to the next path" do
      post confirm_account_organisation_path, params: { account_confirm_organisation_input: { confirm: "yes" } }
      expect(response).to redirect_to("/next-path")
    end
  end

  context "when the user exists and has an organisation but does not have a name" do
    before do
      create(:user, email:, uid: "auth0-uid", provider: "auth0", name: nil)
      sign_in_with_auth0(email:)
    end

    it "redirects to the root path" do
      get edit_account_organisation_path
      expect(response).to redirect_to(root_path)
    end
  end
end
