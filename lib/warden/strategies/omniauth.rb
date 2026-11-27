module Warden::Strategies
  module OmniAuth
    def valid?
      env["omniauth.auth"].present?
    end

    def authenticate!
      logger.debug("Authenticating with :#{request.env['omniauth.strategy'].name} strategy")

      auth_hash = request.env["omniauth.auth"]
      user = prep_user(auth_hash)

      if user.present? && user.organisation.present? && user.name.present?
        success!(user)
      else
        start_pending_user(auth_hash, user)
      end
    end

  private

    def start_pending_user(auth_hash, user)
      pending_user = PendingUser.start(
        session,
        provider: auth_hash[:provider],
        uid: auth_hash[:uid],
        email: auth_hash[:info][:email],
        name: user&.name,
        organisation_id: user&.organisation_id,
        auth0_connection_strategy: auth_hash.dig(:extra, :raw_info, :auth0_connection_strategy),
      )

      redirect!(pending_user.next_account_path)
    end

    def logger
      Rails.logger || env["rack.logger"]
    end

    def prep_user(auth_hash)
      raise NotImplementedError
    end
  end
end
