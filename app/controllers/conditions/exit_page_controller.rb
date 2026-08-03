class Conditions::ExitPageController < PagesController
  before_action :can_add_page_routing, only: %i[new create delete destroy]
  before_action :ensure_answer_value_present, only: %i[new create]

  def new
    exit_page_input = Pages::ExitPageInput.new(form: current_form, page:, answer_value: params[:answer_value])

    render template: "conditions/exit_page/new", locals: { exit_page_input:, preview_html: preview_html(exit_page_input), check_preview_validation: false }
  end

  def create
    exit_page_input = Pages::ExitPageInput.new(exit_page_input_params)

    if exit_page_input.submit
      # TODO: Route number is hardcoded whilst we can only have one value for it
      # https://trello.com/c/BfkZEIgM/3446-set-route-count-dynamically-instead-of-hard-coding-it
      redirect_to show_routes_path(form_id: current_form.id, page_id: page.id), success: t("banner.success.exit_page_created")
    else
      render template: "conditions/exit_page/new", locals: { exit_page_input:, preview_html: preview_html(exit_page_input), check_preview_validation: true }, status: :unprocessable_content
    end
  end

  def edit
    condition = page.routing_conditions.find(params[:condition_id])

    update_exit_page_input = Pages::UpdateExitPageInput.new(form: current_form, page:, record: condition).assign_condition_values

    render template: "conditions/exit_page/edit", locals: { update_exit_page_input:, preview_html: preview_html(update_exit_page_input), check_preview_validation: false }
  end

  def update
    condition = page.routing_conditions.find(params[:condition_id])

    form_params = update_exit_page_input_params.merge(record: condition)

    update_exit_page_input = Pages::UpdateExitPageInput.new(form_params)

    if update_exit_page_input.submit
      redirect_to edit_condition_path(form_id: current_form.id, page_id: page.id, condition_id: update_exit_page_input.record.id), success: t("banner.success.exit_page_updated")
    else
      render template: "conditions/exit_page/edit", locals: { update_exit_page_input:, preview_html: preview_html(update_exit_page_input), check_preview_validation: true }, status: :unprocessable_content
    end
  end

  def delete
    @exit_page = page.routing_conditions.find(params[:condition_id])
    @delete_exit_page_input = Pages::DeleteExitPageInput.new
  end

  def destroy
    condition = page.routing_conditions.find(params[:condition_id])

    # if this isn't an exit page, maybe because of a multiple tabs, redirect to the form pages page
    return redirect_to form_pages_path(current_form.id) unless condition.exit_page?

    @exit_page = condition

    @delete_exit_page_input = Pages::DeleteExitPageInput.new(params.require(:pages_delete_exit_page_input).permit(:confirm))

    unless @delete_exit_page_input.valid?
      return render :delete, status: :unprocessable_content
    end

    unless @delete_exit_page_input.confirmed?
      return redirect_to conditions_exit_page_edit_path(@current_form.id, @page.id, @exit_page.id)
    end

    @exit_page.destroy_and_update_form!

    redirect_to new_condition_path(@current_form.id, @page.id), success: t("banner.success.exit_page_deleted")
  end

  def render_preview
    authorize current_form, :can_view_form?
    exit_page_input = Pages::ExitPageInput.new(exit_page_markdown: params[:markdown])
    exit_page_input.validate if params[:check_preview_validation] == "true"

    render json: { preview_html: preview_html(exit_page_input), errors: exit_page_input.errors[:exit_page_markdown] }.to_json
  end

private

  def can_add_page_routing
    authorize current_form, :can_add_page_routing_conditions?
  end

  def exit_page_input_params
    params.require(:pages_exit_page_input).permit(:exit_page_heading, :exit_page_markdown, :answer_value).merge(form: current_form, page:)
  end

  def update_exit_page_input_params
    params.require(:pages_update_exit_page_input).permit(:exit_page_heading, :exit_page_markdown).merge(form: current_form, page:)
  end

  def ensure_answer_value_present
    return if params[:answer_value].present? || params.dig(:pages_exit_page_input, :answer_value).present?

    redirect_to new_condition_path(current_form.id, page.id)
  end

  def preview_html(exit_page_input_object)
    return t("exit_page.no_content_added_html") if exit_page_input_object.exit_page_markdown.blank?

    GovukFormsMarkdown.render(exit_page_input_object.exit_page_markdown, locale: "en")
  end
end
