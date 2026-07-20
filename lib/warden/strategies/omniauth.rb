module Warden::Strategies
  module OmniAuth
    def valid?
      env["omniauth.auth"].present?
    end

    def authenticate!
      logger.debug("Authenticating with :#{request.env['omniauth.strategy'].name} strategy")

      user = prep_user(request.env["omniauth.auth"])
      fail!("Couldn't process credentials") unless user
      success!(user)
    end

  private

    def logger
      Rails.logger || env["rack.logger"]
    end

    def prep_user(auth_hash)
      raise NotImplementedError
    end
  end
end
