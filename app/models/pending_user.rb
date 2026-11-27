class PendingUser
  SESSION_KEY = "pending_user".freeze

  attr_reader :provider, :uid, :email, :auth0_connection_strategy, :authenticated_at
  attr_accessor :name, :organisation_id

  def self.start(session, provider:, uid:, email:, name: nil, organisation_id: nil, auth0_connection_strategy: nil, authenticated_at: Time.zone.now)
    session[SESSION_KEY] = {
      "provider" => provider.to_s,
      "uid" => uid.to_s,
      "email" => email.to_s,
      "name" => name,
      "organisation_id" => organisation_id,
      "auth0_connection_strategy" => auth0_connection_strategy&.to_s,
      "authenticated_at" => authenticated_at&.utc&.iso8601,
    }

    new(session)
  end

  def self.from_session(session)
    return if session[SESSION_KEY].blank?

    pending_user = new(session)
    return pending_user unless pending_user.expired?

    clear(session)
    nil
  end

  def self.clear(session)
    session.delete(SESSION_KEY)
  end

  def initialize(session)
    @session = session

    data = session[SESSION_KEY]
    @provider = data["provider"]
    @uid = data["uid"]
    @email = data["email"]
    @name = data["name"]
    @organisation_id = data["organisation_id"]
    @auth0_connection_strategy = data["auth0_connection_strategy"]
    @authenticated_at = Time.zone.parse(data["authenticated_at"].to_s)
  end

  def email_domain
    email.split("@").last.downcase.strip
  end

  def expired?
    authenticated_at.nil? || (authenticated_at + Settings.auth_valid_for) <= Time.zone.now
  end

  def save!
    @session[SESSION_KEY] = @session[SESSION_KEY].merge("name" => name, "organisation_id" => organisation_id)
    true
  end

  def next_account_path
    routes = Rails.application.routes.url_helpers
    organisation_id.blank? ? routes.edit_account_organisation_path : routes.edit_account_name_path
  end

  def complete?
    name.present? && organisation_id.present?
  end

  def complete!
    identity = { provider:, uid:, email: }

    user = User.find_for_auth(identity) || User.new(identity)
    user.update!(name:, organisation_id:)
    user.authenticated_at = authenticated_at

    self.class.clear(@session)
    user
  end
end
