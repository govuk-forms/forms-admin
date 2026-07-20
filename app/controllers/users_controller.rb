class UsersController < WebController
  include Pagy::Backend

  after_action :verify_authorized
  after_action :verify_policy_scoped, only: %i[index download]

  def index
    authorize current_user, :can_manage_user?

    users_query = filtered_users

    @pagy, @users = pagy(users_query, limit: 50)

    @filter_input = Users::FilterInput.new(filter_params)
    @filtered_download_path = download_users_path(params: { filter: filter_params })

    render template: "users/index"
  end

  def download
    authorize current_user, :can_download_users?

    send_data Users::CsvService.new(filtered_users).csv,
              type: "text/csv; charset=iso-8859-1",
              disposition: "attachment; filename=govuk_forms_users_#{Time.zone.now}.csv"
  end

  def edit
    authorize current_user, :can_manage_user?
    user
  end

  def update
    authorize current_user, :can_manage_user?

    if UserUpdateService.new(user, user_params).update_user
      redirect_to users_path
    else
      render :edit, status: :unprocessable_content
    end
  end

private

  def filtered_users
    policy_scope(User)
      .by_name(filter_params[:name])
      .by_email(filter_params[:email])
      .by_organisation_id(filter_params[:organisation_id])
      .by_role(filter_params[:role])
      .by_has_access(filter_params[:has_access])
      .for_users_list
  end

  def user_params
    params.require(:user).permit(:has_access, :name, :role, :organisation_id).tap do |p|
      clear_param_if_autocomplete_empty(p, :organisation_id, params.dig(:user, :organisation_id_raw))
    end
  end

  def user
    @user ||= User.find(params[:id])
  end

  def filter_params
    params[:filter]&.permit(:name, :email, :organisation_id, :role, :has_access)&.tap do |filters|
      clear_param_if_autocomplete_empty(filters, :organisation_id, params.dig(:filter, :organisation_id_raw))
    end || {}
  end
end
