class RoutesController < FormsController
  before_action :check_multiple_branches_enabled
  before_action :check_user_has_permission

  def show
    authorize current_form, :can_view_form?
  end

private

  def check_user_has_permission
    authorize current_form, :can_edit_form?
  end

  def check_multiple_branches_enabled
    return if current_form.group.multiple_branches_enabled

    render "errors/not_found", status: :not_found, formats: :html
  end
end
