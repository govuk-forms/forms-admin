class Pages::ExitPagesController < PagesController
  before_action :check_user_has_permission
  before_action :check_multiple_branches_enabled
  before_action :check_page_can_have_exit_pages

  def new
    exit_page_input = Pages::ExitPageInput.new(page: page)

    render locals: { exit_page_input:, preview_html: preview_html(exit_page_input), check_preview_validation: false }
  end

  def create
    exit_page_input = Pages::ExitPageInput.new(exit_page_input_params)

    if exit_page_input.submit
      redirect_to routes_path(form_id: current_form.id), success: t("banner.success.exit_page_saved")
    else
      render :new, locals: { exit_page_input:, preview_html: preview_html(exit_page_input), check_preview_validation: true }, status: :unprocessable_content
    end
  end

  def edit
    exit_page_input = Pages::UpdateExitPageInput.new(exit_page:).assign_exit_page_values

    render locals: { exit_page_input:, preview_html: preview_html(exit_page_input), check_preview_validation: false }
  end

  def update
    exit_page_input = Pages::UpdateExitPageInput.new(update_exit_page_input_params.merge(exit_page:))

    if exit_page_input.submit
      redirect_to routes_path(form_id: current_form.id), success: t("banner.success.exit_page_saved")
    else
      render :edit, locals: { exit_page_input:, preview_html: preview_html(exit_page_input), check_preview_validation: true }, status: :unprocessable_content
    end
  end

  def delete
    delete_confirmation_input = Pages::DeleteExitPageInput.new

    render locals: { delete_confirmation_input:, page:, exit_page: }
  end

  def destroy
    delete_confirmation_input = Pages::DeleteExitPageInput.new(params.require(:pages_delete_exit_page_input).permit(:confirm))

    unless delete_confirmation_input.valid?
      return render :delete, locals: { delete_confirmation_input:, page:, exit_page: }, status: :unprocessable_content
    end

    unless delete_confirmation_input.confirmed?
      return redirect_to edit_exit_page_path(@current_form.id, page.id, exit_page.id)
    end

    current_form.save_question_changes! do
      exit_page.destroy!
    end

    redirect_to routes_path(@current_form.id), success: t("banner.success.exit_page_deleted")
  end

  def render_preview
    exit_page_input = Pages::ExitPageInput.new(markdown: params[:markdown])
    exit_page_input.validate if params[:check_preview_validation] == "true"

    render json: { preview_html: preview_html(exit_page_input), errors: exit_page_input.errors[:markdown] }.to_json
  end

private

  def exit_page
    @exit_page ||= page.exit_pages.find(params.require(:id))
  end

  def exit_page_input_params
    params.require(:pages_exit_page_input).permit(:heading, :markdown).merge(page:)
  end

  def update_exit_page_input_params
    params.require(:pages_update_exit_page_input).permit(:heading, :markdown).merge(page:)
  end

  def check_user_has_permission
    authorize current_form, :can_edit_form?
  end

  def check_multiple_branches_enabled
    return if FeatureService.new(group: current_form.group).enabled?(:multiple_branches)

    render "errors/not_found", status: :not_found, formats: :html
  end

  def check_page_can_have_exit_pages
    return if Forms::RoutesInput.route_with_selection_options?(page)

    render "errors/not_found", status: :not_found, formats: :html
  end

  def preview_html(exit_page_input_object)
    return t("exit_page.no_content_added_html") if exit_page_input_object.markdown.blank?

    GovukFormsMarkdown.render(exit_page_input_object.markdown, locale: "en")
  end
end
