require "rails_helper"

describe Account::NamesController do
  let(:email) { "user@example.gov.uk" }
  let(:organisation) { create(:organisation) }

  before do
    allow(Settings).to receive(:auth_provider).and_return("auth0")
  end

  context "when there is no pending user" do
    it "redirects to the root path" do
      get edit_account_name_path
      expect(response).to redirect_to(root_path)
    end
  end

  context "when the user does not exist yet" do
    before do
      sign_in_with_auth0(email:)
    end

    describe "GET #edit" do
      it "renders the edit template" do
        get edit_account_name_path
        expect(response).to render_template(:edit)
        expect(assigns(:name_input)).to be_a(Account::NameInput)
      end
    end

    describe "PUT #update" do
      context "with valid params" do
        let(:valid_params) { { account_name_input: { name: "John Doe" } } }

        it "stores the name in the session without creating the user" do
          expect {
            put account_name_path, params: valid_params
          }.not_to change(User, :count)

          expect(session[PendingUser::SESSION_KEY]).to include("name" => "John Doe")
        end

        it "redirects to the organisation page" do
          put account_name_path, params: valid_params
          expect(response).to redirect_to(edit_account_organisation_path)
        end

        context "when the organisation has already been chosen" do
          before do
            create(:organisation, organisation_domains: [create(:organisation_domain, domain: "example.gov.uk")])
            post confirm_account_organisation_path, params: { account_confirm_organisation_input: { confirm: "yes" } }
          end

          it "creates the user and signs them in" do
            expect {
              put account_name_path, params: valid_params
            }.to change(User, :count).by(1)

            user = User.find_by(email:)
            expect(user.name).to eq("John Doe")
            expect(request.env["warden"].user).to eq user
            expect(request.env["warden"].session["auth0_connection_strategy"]).to eq "email"
            expect(session[PendingUser::SESSION_KEY]).to be_nil
          end

          it "redirects to the next account setup page" do
            put account_name_path, params: valid_params
            expect(response).to redirect_to(edit_account_terms_of_use_path)
          end
        end
      end

      context "with invalid params" do
        let(:invalid_params) { { account_name_input: { name: "" } } }

        it "does not store the name" do
          put account_name_path, params: invalid_params
          expect(session[PendingUser::SESSION_KEY]).to include("name" => nil)
        end

        it "renders the edit template" do
          put account_name_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_content)
          expect(response).to render_template(:edit)
        end
      end
    end
  end

  context "when the user exists but does not have a name" do
    let!(:user) { create(:user, email:, uid: "auth0-uid", provider: "auth0", name: nil, organisation:) }

    before do
      sign_in_with_auth0(email:)

      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(AfterSignInPathHelper).to receive(:after_sign_in_next_path).and_return("/next-path")
      # rubocop:enable RSpec/AnyInstance
    end

    it "redirects to the name page when signing in" do
      expect(response).to redirect_to(edit_account_name_path)
    end

    it "updates the user's name and signs them in" do
      put account_name_path, params: { account_name_input: { name: "John Doe" } }

      expect(user.reload.name).to eq("John Doe")
      expect(request.env["warden"].user).to eq user
    end

    it "redirects to the next path" do
      put account_name_path, params: { account_name_input: { name: "John Doe" } }
      expect(response).to redirect_to("/next-path")
    end
  end

  context "when the user exists and has a name but does not have an organisation" do
    before do
      create(:user, :with_no_org, email:, uid: "auth0-uid", provider: "auth0", name: "John Smith")
      sign_in_with_auth0(email:)
    end

    it "redirects to the root path" do
      get edit_account_name_path
      expect(response).to redirect_to(root_path)
    end
  end
end
