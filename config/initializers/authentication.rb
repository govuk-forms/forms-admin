Rails.application.config.before_initialize do
  # Configure Warden session management middleware first so it wraps the
  # OmniAuth strategies below - this means `env["warden"]` is set up before
  # an OmniAuth callback redirects on failure.
  Rails.application.config.app_middleware.use(Warden::Manager) do |warden|
    warden.default_strategies(Settings.auth_provider.to_sym)
    warden.failure_app = AuthenticationController
  end

  # OmniAuth::Builder handles the `/auth/failure` endpoint, which OmniAuth
  # redirects to when a strategy fails. Previously installed by the gds-sso gem.
  Rails.application.config.app_middleware.use(OmniAuth::Builder) {}

  # Configure OmniAuth authentication middleware
  # add Auth0 provider
  Rails.application.config.app_middleware.use(
    OmniAuth::Strategies::Auth0,
    setup: lambda do |env|
      is_e2e = env["omniauth.strategy"].request.params["auth"] == "e2e"

      # use the e2e client if the request has the auth header is set to "e2e"
      env["omniauth.strategy"].options[:client_id] = is_e2e ? Settings.auth0.e2e_client_id : Settings.auth0.client_id
      env["omniauth.strategy"].options[:client_secret] = is_e2e ? Settings.auth0.e2e_client_secret : Settings.auth0.client_secret
      env["omniauth.strategy"].options[:domain] = Settings.auth0.domain
      env["omniauth.strategy"].options[:authorize_params] = {
        scope: "openid email",
      }

      # append the auth query param in e2e tests to ensure the correct client is used in the callback
      env["omniauth.strategy"].options[:callback_path] = is_e2e ? "/auth/auth0/callback?auth=e2e" : "/auth/auth0/callback"
    end,
  )

  # add developer provider
  if Rails.env.development? || Rails.env.test? || (Settings.forms_env == "review")
    Rails.application.config.app_middleware.use(
      OmniAuth::Strategies::Developer,
      fields: [:email],
    )
  end

  # add auth provider for user research environment
  if Settings.auth_provider == "user_research" || Rails.env.test?
    require "omniauth/strategies/username_and_password"

    Rails.application.config.app_middleware.use(
      OmniAuth::Strategies::UsernameAndPassword,
      name: "user-research",
      username: Settings.user_research.auth.username,
      password: Settings.user_research.auth.password,
      email_domain: "example.gov.uk",
    )
  end
end

# Need to do this because Signon allows both GET and POST requests
OmniAuth.config.allowed_request_methods = %i[post]

# Previously set by the gds-sso gem's railtie. Without it OmniAuth falls back
# to its own STDOUT logger, so strategy debug/error lines bypass Rails logging
# (and clutter test output) instead of going through Rails.logger.
OmniAuth.config.logger = Rails.logger

# Silence the warning about extra tokens - we expect id and access_token from
# auth0 see https://gitlab.com/oauth-xx/oauth2/#global-configuration
OAuth2.configure do |config|
  config.silence_extra_tokens_warning = true
end

# Keep users signed in only for as long as Settings.auth_valid_for allows, regardless
# of auth provider. Replaces gds-sso's own serialize_into_session/serialize_from_session,
# which read the equivalent value from GDS::SSO::Config.auth_valid_for.
Warden::Manager.serialize_into_session do |user|
  [user.uid, Time.zone.now.utc.iso8601] if user.respond_to?(:uid) && user.uid
end

Warden::Manager.serialize_from_session do |(uid, auth_timestamp)|
  if auth_timestamp.is_a?(String)
    begin
      auth_timestamp = Time.zone.parse(auth_timestamp)
    rescue ArgumentError
      auth_timestamp = nil
    end
  end

  if auth_timestamp && ((auth_timestamp + Settings.auth_valid_for) > Time.zone.now.utc)
    User.where(uid:).first
  end
end

# store the auth0 connection used to login in the warden session
Warden::Manager.after_authentication do |user, auth, _opts|
  if user.provider == "auth0"
    auth.session["auth0_connection_strategy"] = auth.env["omniauth.auth"][:extra][:raw_info][:auth0_connection_strategy]
  end

  user.signed_in!
end
