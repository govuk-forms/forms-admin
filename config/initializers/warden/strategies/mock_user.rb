Warden::Strategies.add(:mock_user) do
  def valid?
    true
  end

  def authenticate!
    logger.warn("Authenticating with mock_user strategy")

    user = User.first
    if user
      success!(user)
    else
      fail!("No user found in the database to sign in as. Create a user first, e.g. via bin/rails db:seed.")
    end
  end

private

  def logger
    Rails.logger || env["rack.logger"]
  end
end
