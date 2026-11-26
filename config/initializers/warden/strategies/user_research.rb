require "warden/strategies/omniauth"

Warden::Strategies.add(:user_research) do
  include Warden::Strategies::OmniAuth

  def valid?
    Settings.forms_env == "user-research" && Settings.auth_provider == "user_research" && super
  end

private

  def prep_user(auth_hash)
    attributes = {
      name: auth_hash[:info][:name],
      email: auth_hash[:info][:email],
      organisation:,
      provider: Settings.auth_provider,
      uid: auth_hash[:uid],
      terms_agreed_at: Time.zone.now,
      research_contact_status: "declined",
      user_research_opted_in_at: Time.zone.now,
    }

    User.find_for_auth(attributes) || User.create!(attributes)
  end

  def organisation
    Organisation.find_or_initialize_by(
      name: Settings.user_research.organisation.name,
      slug: Settings.user_research.organisation.slug,
      govuk_content_id: Settings.user_research.organisation.govuk_content_id,
    )
  end
end
