module PendingUserAccountSetup
  extend ActiveSupport::Concern

  included do
    skip_before_action :authenticate_and_check_access
    skip_before_action :redirect_if_account_not_completed
    before_action :redirect_unless_pending_user
  end

private

  def redirect_unless_pending_user
    redirect_to root_path unless pending_user?
  end

  def complete_account_setup_if_ready
    return unless pending_user.complete?

    auth0_connection_strategy = pending_user.auth0_connection_strategy
    user = pending_user.complete!

    warden.set_user(user)
    warden.session["auth0_connection_strategy"] = auth0_connection_strategy if user.provider == "auth0"
    user.signed_in!
  end

  def next_path
    pending_user? ? pending_user.next_account_path : after_sign_in_next_path
  end
end
