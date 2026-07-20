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
