class AuthenticationController < WebController
  skip_before_action :authenticate_and_check_access
  skip_before_action :redirect_if_account_not_completed
  protect_from_forgery with: :null_session, only: %i[redirect_to_sign_in]

  include AfterSignInPathHelper

  layout false

  def self.call(env)
    action(:redirect_to_sign_in).call(env)
  end

  def redirect_to_sign_in
    store_location(attempted_path) if request.get?

    redirect_to(sign_in_url(request.query_parameters))
  end

  def callback_from_omniauth
    authenticate_user!
    redirect_to after_sign_in_next_path
  end

  def sign_in
    @is_e2e_user = e2e_user?
    render "authentications/sign_in", layout: "application"
  end

  def sign_up
    store_location root_path
    @is_e2e_user = e2e_user?
    render "authentications/sign_up", layout: "application"
  end

  def sign_out
    # get current_user before user is logged out of warden
    auth_provider = current_user&.provider

    if user_signed_in
      warden.logout
      redirect_to send(:"#{auth_provider}_sign_out_url"), allow_other_host: true
    else
      redirect_to root_path
    end
  end

  def failure
    render "authentications/failure"
  end

private

  def attempted_path
    request.env["warden.options"][:attempted_path]
  end

  def auth0_sign_out_url
    request_params = {
      returnTo: root_url,
      client_id: Settings.auth0.client_id,
    }

    URI::HTTPS.build(host: Settings.auth0.domain, path: "/v2/logout", query: request_params.to_query).to_s
  end

  def developer_sign_out_url
    root_path
  end

  alias_method :user_research_sign_out_url, :developer_sign_out_url

  def mock_user_sign_out_url
    root_path
  end

  def e2e_user?
    # this should be appended to the first request in the e2e tests to activate
    # the username/password flow
    params.permit(:auth)[:auth] == "e2e"
  end

  def params_to_log
    nil
  end
end
