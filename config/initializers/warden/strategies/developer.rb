require "warden/strategies/omniauth"

Warden::Strategies.add(:developer) do
  include Warden::Strategies::OmniAuth

private

  def prep_user(auth_hash)
    attributes = {
      provider: auth_hash[:provider],
      uid: auth_hash[:uid],
      email: auth_hash[:info][:email],
    }

    User.find_for_auth(attributes) || User.create!(attributes)
  end
end
