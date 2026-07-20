Warden::Strategies.add(:basic_auth) do
  include ActionController::HttpAuthentication::Basic::ControllerMethods

  attr_writer :status

  def request
    @request ||= ActionDispatch::Request.new(@env)
  end

  def response_body=(message)
    @message = message
  end

  def authenticate!
    logger.debug("Authenticating with basic_auth strategy")

    http_basic_authenticate_or_request_with(
      name: Settings.basic_auth.username,
      password: Settings.basic_auth.password,
    )

    if status.nil?
      success! User.find_or_initialize_by(
        name: Settings.basic_auth.username,
        email: "#{Settings.basic_auth.username}@example.gov.uk",
        provider: :basic_auth,
        organisation: Organisation.find_or_initialize_by(
          name: Settings.basic_auth.organisation.name,
          slug: Settings.basic_auth.organisation.slug,
          govuk_content_id: Settings.basic_auth.organisation.govuk_content_id,
        ),
      )
    else
      custom! [@status, headers, [@message]]
    end
  end

private

  def logger
    Rails.logger || env["rack.logger"]
  end
end
