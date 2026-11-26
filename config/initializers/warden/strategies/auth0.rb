require "warden/strategies/omniauth"

Warden::Strategies.add(:auth0) do
  include Warden::Strategies::OmniAuth

private

  def prep_user(auth_hash)
    CurrentLoggingAttributes.auth0_session_id = request.env.dig("omniauth.auth", "extra", "raw_info", "sid")
    attributes = {
      provider: auth_hash[:provider],
      uid: auth_hash[:uid],
      email: auth_hash[:info][:email],
    }

    User.find_for_auth(attributes) || User.create!(attributes)
  end
end
