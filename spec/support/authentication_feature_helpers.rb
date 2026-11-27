module AuthenticationFeatureHelpers
  include Warden::Test::Helpers

  @run_callbacks = false

  def set_run_callbacks(value)
    @run_callbacks = value
  end

  def login_as(user, opts = {})
    opts[:run_callbacks] = @run_callbacks
    super user, opts
  end

  def test_org
    @test_org ||= FactoryBot.create(:organisation, :with_signed_mou, slug: "test-org")
  end

  def super_admin_user
    @super_admin_user ||= FactoryBot.create(:super_admin_user, organisation: test_org)
  end

  def organisation_admin_user
    @organisation_admin_user ||= FactoryBot.create(:organisation_admin_user, organisation: test_org)
  end

  def standard_user
    @standard_user ||= FactoryBot.create(:user, :standard, organisation: test_org)
  end

  def login_as_super_admin_user(user = nil)
    login_as(user || super_admin_user)

    # All super-admins should have logged in via Auth0 with the Google workspace login
    Warden.on_next_request do |proxy|
      proxy.session["auth0_connection_strategy"] = "google-apps"
    end
  end

  def sign_in_with_auth0(email:, uid: "auth0-uid", auth0_connection_strategy: "email")
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:auth0] = Faker::Omniauth.auth0(uid:, email:)
    OmniAuth.config.mock_auth[:auth0][:extra][:raw_info][:auth0_connection_strategy] = auth0_connection_strategy

    post "/auth/auth0"
    get "/auth/auth0/callback"
  ensure
    OmniAuth.config.mock_auth[:auth0] = nil
    OmniAuth.config.test_mode = false
  end

  def login_as_organisation_admin_user
    login_as organisation_admin_user
  end

  def login_as_standard_user
    login_as standard_user
  end
end

RSpec.configure do |config|
  config.include AuthenticationFeatureHelpers, type: :feature
  config.include AuthenticationFeatureHelpers, type: :request

  config.before(:example, type: :feature) do
    Warden.test_mode!
  end
  config.before(:example, type: :request) do
    Warden.test_mode!
  end

  config.after(:example, type: :feature) do
    Warden.test_reset!
  end
  config.after(:example, type: :request) do
    Warden.test_reset!
  end
end
