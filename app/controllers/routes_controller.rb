class RoutesController < FormsController
  before_action :check_multiple_branches_enabled
  before_action :check_user_has_permission

  def show
    authorize current_form, :can_view_form?
    @routes_input = Forms::RoutesInput.new(form: form_with_pages_and_conditions).assign_form_values
    @routes_input.validate
  end

  def create
    authorize current_form, :can_edit_form?

    @routes_input = Forms::RoutesInput.new(routes_params)

    if @routes_input.submit
      if redirect_params.key?(:new_exit_page)
        redirect_to new_exit_page_path(@routes_input.form, redirect_params[:new_exit_page])
      else
        redirect_to form_pages_path(@routes_input.form), success: t("banner.success.form.routing_saved")
      end
    else
      render :show, status: :unprocessable_content
    end
  end

private

  def check_user_has_permission
    authorize current_form, :can_edit_form?
  end

  def check_multiple_branches_enabled
    return if current_form.group.multiple_branches_enabled

    render "errors/not_found", status: :not_found, formats: :html
  end

  def routes_params
    params.require(:forms_routes_input).permit(routes_attributes: %i[id page_id answer_value goto]).merge(form: form_with_pages_and_conditions)
  end

  def redirect_params
    params.permit(:new_exit_page)
  end

  def form_with_pages_and_conditions
    Form.includes(pages: [:routing_conditions]).find(current_form.id)
  end
end
