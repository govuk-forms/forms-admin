class PagesController < FormsController
  before_action :check_user_has_permission
  before_action :clear_draft_questions_data, only: %i[index move_page]
  after_action :verify_authorized
  after_action :set_answer_type_logging_attribute

  def index
    @pages = current_form.pages
    @mark_complete_input = Forms::MarkPagesSectionCompleteInput.new(form: current_form).assign_form_values
    log_validation_errors
    render :index, locals: { current_form: }
  end

  def delete
    @url = destroy_page_path(current_form.id, page.id)
    @item_name = page.question_text
    @back_url = edit_question_path(current_form.id, page.id)

    @page_goto_conditions = page.goto_conditions

    if FeatureService.new(group: current_form.group).enabled?(:multiple_branches)
      @page_conditions = page.routing_conditions
      @routing = @page_conditions + @page_goto_conditions + page.exit_pages
      if @routing.present?
        @routing_banner_heading = routing_banner_heading(@page_conditions, @page_goto_conditions, page.exit_pages)
        @routing_banner_html = routing_banner_html(@page_conditions, @page_goto_conditions, page.exit_pages)
      end
    elsif page.routing_conditions.any? && page.routing_conditions.first.secondary_skip?
      @routing = :start_of_secondary_skip_route

      # route page is condition check page
      @route_page = page.routing_conditions.first.check_page
    elsif page.routing_conditions.any?
      @routing = :start_of_route

      # route page is us
      @route_page = page
    elsif @page_goto_conditions.any? && @page_goto_conditions.first.secondary_skip?
      @routing = :end_of_secondary_skip_route

      # route page is condition check page
      @route_page = @page_goto_conditions.first.check_page
    elsif @page_goto_conditions.any?
      @routing = :end_of_route

      # route page is condition routing page
      @route_page = @page_goto_conditions.first.routing_page
    end
    @delete_confirmation_input = Pages::DeleteConfirmationInput.new

    render locals: { current_form: }
  end

  def destroy
    @url = destroy_page_path(current_form.id, page.id)
    @item_name = page.question_text
    @back_url = edit_question_path(current_form.id, page.id)

    @delete_confirmation_input = Pages::DeleteConfirmationInput.new(
      params.require(:pages_delete_confirmation_input).permit(:confirm),
    )

    unless @delete_confirmation_input.valid?
      return render :delete, locals: { current_form: }
    end

    unless @delete_confirmation_input.confirmed?
      return redirect_to @back_url
    end

    page.destroy_and_update_form!
    redirect_to form_pages_path(current_form), status: :see_other, success: t(".success", question_text: page.question_text)
  end

  def start_new_question
    clear_draft_questions_data
    redirect_to type_of_answer_create_path(form_id: current_form.id)
  end

  def move_page
    page = current_form.pages.find(move_params[:page_id])
    page.move_page(move_params[:direction])

    success_message = t("banner.success.form.page_moved",
                        question_text: page.question_text,
                        direction: move_params[:direction],
                        question_number: page.position)

    redirect_to form_pages_path, success: success_message
  end

  def mark_pages_section_completed
    @pages = current_form.pages
    @mark_complete_input = Forms::MarkPagesSectionCompleteInput.new(mark_complete_input_params)

    if @mark_complete_input.submit
      success_message = if @mark_complete_input.mark_complete == "true"
                          t("banner.success.form.pages_saved_and_section_completed")
                        else
                          t("banner.success.form.pages_saved")
                        end
      redirect_to form_path(current_form.id), success: success_message
    else
      @mark_complete_input.mark_complete = "false"
      render "pages/index", locals: { current_form: }, status: :unprocessable_content
    end
  end

private

  def clear_draft_questions_data
    DraftQuestion.destroy_by(form_id: current_form.id, user_id: current_user.id) if current_user.present? && current_form.present?
  end

  def check_user_has_permission
    authorize current_form, :can_edit_form?
  end

  def redirect_if_unexpected_answer_type(expected_answer_type)
    return if draft_question.answer_type == expected_answer_type

    if page_id.present?
      redirect_to edit_question_path(current_form.id, page_id)
    else
      redirect_to Pages::AddOrEditQuestionService.new(form_id: current_form.id).new_or_edit_path_for_answer_type(draft_question.answer_type)
    end
  end

  def page
    @page ||= current_form.pages.find(page_id)
  end

  def draft_question
    @draft_question ||= if page_id.present?
                          setup_draft_question_for_existing_page
                        else
                          DraftQuestion.find_or_initialize_by(form_id: current_form.id, user_id: current_user.id)
                        end
  end

  def page_id
    params[:page_id]
  end

  def move_params
    form_id = params.require(:form_id)
    p = params.require(:move_direction).permit(%i[up down])
    direction = p[:up] ? :up : :down
    page_id = p[direction]
    @move_params ||= { form_id:, page_id:, direction: }
  end

  def setup_draft_question_for_existing_page
    edit_draft_question = DraftQuestion.find_or_initialize_by(form_id: current_form.id, user_id: current_user.id, page_id: page.id)

    if edit_draft_question.new_record?
      attributes = page.attributes
                       .slice(*edit_draft_question.attribute_names)
                       .except("id")
      edit_draft_question.attributes = attributes
      edit_draft_question.save!
    end
    edit_draft_question
  end

  def mark_complete_input_params
    params.require(:forms_mark_pages_section_complete_input).permit(:mark_complete).merge(form: current_form)
  end

  def set_answer_type_logging_attribute
    if @draft_question.present?
      CurrentLoggingAttributes.answer_type = @draft_question.answer_type
    elsif @page.present?
      CurrentLoggingAttributes.answer_type = @page.answer_type
    end
  end

  def log_validation_errors
    # these validation errors don't come from an input object, so we log them ourselves
    errors = []
    current_form.conditions.each do |condition|
      condition.validation_errors.each do |error|
        errors << error.name
        error_type = condition.secondary_skip? ? "any_other_answer_route.#{error.name}" : error.name
        AnalyticsService.track_validation_errors(input_object_name: "PageList", field: :condition, error_type:, form_name: current_form.name)
      end
    end

    CurrentLoggingAttributes.validation_errors = errors.map { |error| "PageList: #{error}" } if errors.any?
  end

  def routing_banner_heading(page_conditions, goto_conditions, exit_pages)
    if page_conditions.present? && goto_conditions.present?
      t("pages.delete.routing_and_goto_heading", question_number: page.position)
    elsif page_conditions.present?
      t("pages.delete.routing_heading", question_number: page.position, count: page_conditions.count)
    elsif goto_conditions.present?
      t("pages.delete.goto_heading", question_number: page.position, count: goto_conditions.count)
    elsif exit_pages.present?
      t("pages.delete.exit_pages_heading", question_number: page.position, count: exit_pages.count)
    end
  end

  def routing_banner_html(page_conditions, goto_conditions, exit_pages)
    if page_conditions.present? && goto_conditions.present?
      routes_and_exit_pages = helpers.routes_and_exit_pages(page, count_goto_conditions: true)
      t("pages.delete.routing_and_goto_html", routes_and_exit_pages:, routes_href: routes_path(current_form.id))
    elsif page_conditions.present?
      routes_and_exit_pages = helpers.routes_and_exit_pages(page)
      t("pages.delete.routing_html", question_number: page.position, routes_and_exit_pages:, routes_href: routes_path(current_form.id))
    elsif goto_conditions.present?
      t("pages.delete.goto_html", question_number: page.position, count: goto_conditions.count, routes_href: routes_path(current_form.id))
    elsif exit_pages.present?
      exit_pages = t("helpers.pages.exit_pages", count: exit_pages.count)
      t("pages.delete.exit_pages_html", question_number: page.position, exit_pages:, routes_href: routes_path(current_form.id))
    end
  end
end
