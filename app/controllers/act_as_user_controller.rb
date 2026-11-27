class ActAsUserController < WebController
  before_action :check_act_as_user_is_enabled
  before_action :check_user_super_admin, only: :start
  before_action :check_currently_acting_as_user, only: :stop
  skip_before_action :redirect_if_account_not_completed, only: :stop

  def start
    target_user = User.find_by(id: params[:user_id])
    act_as(target_user) unless target_user.super_admin? || !target_user.has_access? || !account_set_up?(target_user)

    redirect_to root_path
  end

  def stop
    stop_acting_as_user

    redirect_to root_path
  end

private

  def check_act_as_user_is_enabled
    raise ActionController::RoutingError, "Acting as user not enabled" unless Settings.act_as_user_enabled
  end

  def check_user_super_admin
    raise Pundit::NotAuthorizedError unless current_user.super_admin?
  end

  def check_currently_acting_as_user
    redirect_to root_path if User.find_by(id: session[:original_user_id]).blank?
  end

  def account_set_up?(user)
    user.organisation.present? && user.name.present?
  end

  def act_as(user)
    session[:original_user_id] = current_user.id
    session[:acting_as_user_id] = user.id

    warden.set_user(user)

    @current_user = user
  end

  def stop_acting_as_user
    original_user = User.find_by(id: session[:original_user_id])

    warden.set_user(original_user)
    @current_user = original_user

    session[:acting_as_user_id] = nil
    session[:original_user_id] = nil
  end
end
