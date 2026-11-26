require "rails_helper"

RSpec.describe "usage of omniauth-auth0 gem" do
  include AuthenticationFeatureHelpers

  before do
    set_run_callbacks(true)
    allow(Settings).to receive(:auth_provider).and_return("auth0")
    OmniAuth.config.test_mode = true
  end

  after do
    set_run_callbacks(false)
    OmniAuth.config.mock_auth[:auth0] = nil
    OmniAuth.config.test_mode = false
  end

  let(:omniauth_hash) do
    Faker::Omniauth.auth0(
      uid: "123456",
      email: "test@example.com",
    )
  end

  describe "authentication" do
    it "redirects to OmniAuth when no user is logged in" do
      logout

      get root_path

      expect(response).to redirect_to(sign_in_path)
    end

    it "authenticates with OmniAuth and Warden" do
      create :user, provider: "auth0", uid: "123456", email: "test@example.com"
      OmniAuth.config.mock_auth[:auth0] = omniauth_hash

      post "/auth/auth0"

      expect(response).to redirect_to("/auth/auth0/callback")

      get "/auth/auth0/callback"

      expect(request.env["warden"].authenticated?).to be true
    end

    context "when the user does not exist yet" do
      before do
        omniauth_hash[:extra][:raw_info][:auth0_connection_strategy] = "email"
        OmniAuth.config.mock_auth[:auth0] = omniauth_hash
        post "/auth/auth0"
      end

      it "does not create the user" do
        expect {
          get "/auth/auth0/callback"
        }.not_to change(User, :count)
      end

      it "does not authenticate the user with Warden" do
        get "/auth/auth0/callback"
        expect(request.env["warden"].authenticated?).to be false
      end

      it "stores the user's details in the session" do
        get "/auth/auth0/callback"

        expect(session[PendingUser::SESSION_KEY]).to eq(
          "provider" => "auth0",
          "uid" => "123456",
          "email" => "test@example.com",
          "name" => nil,
          "organisation_id" => nil,
          "auth0_connection_strategy" => "email",
        )
      end

      it "redirects to the page to choose their organisation" do
        get "/auth/auth0/callback"
        expect(response).to redirect_to(edit_account_organisation_path)
      end

      it "redirects other pages to the page to choose their organisation" do
        get "/auth/auth0/callback"
        get groups_path
        expect(response).to redirect_to(edit_account_organisation_path)
      end

      context "and the user then signs in as an existing user" do
        let(:existing_user) { create :user, provider: "auth0", uid: "654321", email: "existing@example.com" }

        it "clears the pending user details from the session" do
          get "/auth/auth0/callback"

          OmniAuth.config.mock_auth[:auth0] = Faker::Omniauth.auth0(uid: existing_user.uid, email: existing_user.email)

          post "/auth/auth0"
          get "/auth/auth0/callback"

          expect(session[PendingUser::SESSION_KEY]).to be_nil
          expect(request.env["warden"].user).to eq existing_user
        end
      end
    end

    context "when the user exists but does not have an organisation or a name" do
      before do
        create :user, :with_no_org, provider: "auth0", uid: "123456", email: "test@example.com", name: nil
        OmniAuth.config.mock_auth[:auth0] = omniauth_hash
        post "/auth/auth0"
        get "/auth/auth0/callback"
      end

      it "does not authenticate the user with Warden" do
        expect(request.env["warden"].authenticated?).to be false
      end

      it "redirects to the page to choose their organisation" do
        expect(response).to redirect_to(edit_account_organisation_path)
      end
    end

    context "when the user exists and has an organisation but not a name" do
      let!(:user) { create :user, provider: "auth0", uid: "123456", email: "test@example.com", name: nil }

      before do
        OmniAuth.config.mock_auth[:auth0] = omniauth_hash
        post "/auth/auth0"
        get "/auth/auth0/callback"
      end

      it "stores the user's organisation in the session" do
        expect(session[PendingUser::SESSION_KEY]).to include("organisation_id" => user.organisation_id)
      end

      it "redirects to the page to enter their name" do
        expect(response).to redirect_to(edit_account_name_path)
      end
    end
  end

  describe "signing out" do
    before do
      allow(Settings.auth0).to receive_messages(domain: "test", client_id: "baz")
      OmniAuth.config.mock_auth[:auth0] = omniauth_hash
    end

    context "when the user is signed in" do
      before do
        create :user, provider: "auth0", uid: "123456", email: "test@example.com"
        post "/auth/auth0"
        get "/auth/auth0/callback"
      end

      it "signs the user out of auth0" do
        get sign_out_path

        expect(response).to redirect_to("https://test/v2/logout?client_id=baz&returnTo=http%3A%2F%2Fwww.example.com%2F")
      end
    end

    context "when the user has not finished setting up their account" do
      before do
        post "/auth/auth0"
        get "/auth/auth0/callback"
      end

      it "signs the user out of auth0" do
        get sign_out_path

        expect(response).to redirect_to("https://test/v2/logout?client_id=baz&returnTo=http%3A%2F%2Fwww.example.com%2F")
      end

      it "clears the pending user details from the session" do
        get sign_out_path

        expect(session[PendingUser::SESSION_KEY]).to be_nil
      end
    end
  end

  describe User do
    describe ".find_for_auth" do
      it "is called by the auth0 Warden strategy" do
        create :user, provider: "auth0", uid: "123456", email: "test@example.com"
        allow(described_class).to receive(:find_for_auth).and_call_original

        OmniAuth.config.mock_auth[:auth0] = omniauth_hash

        post "/auth/auth0"
        get "/auth/auth0/callback"

        expect(described_class).to have_received(:find_for_auth).with(
          provider: "auth0",
          uid: "123456",
          email: "test@example.com",
        )

        winning_strategy = request.env["warden"].winning_strategy
        expect(winning_strategy).to be_a Warden::Strategies[:auth0]
        expect(winning_strategy).to be_successful
      end
    end
  end

  describe "failure page" do
    it "is shown if there is an authentication failure with external provider" do
      OmniAuth.config.mock_auth[:auth0] = :invalid_credentials

      logout

      post "/auth/auth0"

      expect(response).to redirect_to "/auth/auth0/callback"
      follow_redirect!

      expect(response).to redirect_to "/auth/failure?message=invalid_credentials&strategy=auth0"
    end

    it "has a retry link" do
      get "/auth/failure?message=invalid_credentials&strategy=auth0"

      expect(response.body).to include '<a href="/sign-in">try again</a>'
    end
  end

  describe "Auth0 client selection" do
    before do
      allow(Settings).to receive(:auth0).and_return(
        OpenStruct.new(
          client_id: "1234",
          client_secret: "abcd",
          e2e_client_id: "4321",
          e2e_client_secret: "dcba",
        ),
      )

      OmniAuth.config.mock_auth[:auth0] = omniauth_hash
    end

    it "uses e2e client when auth is set to e2e" do
      get "/auth/auth0/callback", params: { auth: "e2e" }

      strategy = request.env["omniauth.strategy"]

      expect(strategy.options[:client_id]).to eq("4321")
      expect(strategy.options[:client_secret]).to eq("dcba")
      expect(strategy.options[:callback_path]).to eq("/auth/auth0/callback?auth=e2e")
      expect(strategy.options[:authorize_params][:connection]).to be_nil
    end

    it "uses default client when auth is not set to e2e" do
      get "/auth/auth0/callback"

      strategy = request.env["omniauth.strategy"]

      expect(strategy.options[:client_id]).to eq("1234")
      expect(strategy.options[:client_secret]).to eq("abcd")
      expect(strategy.options[:callback_path]).to eq("/auth/auth0/callback")
      expect(strategy.options[:authorize_params][:connection]).to be_nil
    end
  end

  describe "Google workspace integration" do
    let(:form) { create :form, name: "Apply for a juggling license" }

    context "when a super-admin user is logged in" do
      let(:user) { super_admin_user }

      context "and authenticated via Google" do
        [
          "/groups",
          "/users",
        ].each do |path|
          it "when accessing #{path}, returns http code 200 for #{path}" do
            user.provider = "auth0"
            omniauth_hash[:info][:email] = user.email
            omniauth_hash[:extra][:raw_info][:auth0_connection_strategy] = "google-apps"

            OmniAuth.config.mock_auth[:auth0] = omniauth_hash

            post "/auth/auth0"

            expect(response).to redirect_to("/auth/auth0/callback")

            get "/auth/auth0/callback"

            get path

            expect(response).to have_http_status(:ok)
          end
        end
      end

      context "and didn't authenticate via Google" do
        [
          "/",
          "/users",
        ].each do |path|
          context "when accessing #{path}" do
            before do
              user.provider = "auth0"
              omniauth_hash[:info][:email] = user.email
              omniauth_hash[:extra][:raw_info][:auth0_connection_strategy] = "email"

              OmniAuth.config.mock_auth[:auth0] = omniauth_hash

              post "/auth/auth0"

              get "/auth/auth0/callback"

              get path
            end

            it "returns http code 403 for #{path}" do
              expect(response).to have_http_status(:forbidden)
            end

            it "renders the access denied page" do
              expect(response).to render_template("errors/access_denied")
              expect(response.body).to include("if you think this is incorrect.")
            end
          end
        end
      end
    end

    context "when a non-super-admin user is logged in" do
      let(:user) { standard_user }

      context "and authenticated via Google" do
        context "when accessing /groups," do
          %w[google-apps invalid-connection].each do |connection|
            context "and using #{connection}," do
              it "returns http code 200" do
                user.provider = "auth0"
                omniauth_hash[:info][:email] = user.email
                omniauth_hash[:extra][:raw_info][:auth0_connection_strategy] = connection

                OmniAuth.config.mock_auth[:auth0] = omniauth_hash

                post "/auth/auth0"

                expect(response).to redirect_to("/auth/auth0/callback")

                get "/auth/auth0/callback"

                get groups_path

                expect(response).to have_http_status(:ok)
              end
            end
          end
        end
      end
    end
  end
end
