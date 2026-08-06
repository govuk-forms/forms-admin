class Pages::ConditionsController < PagesController
  before_action :can_add_page_routing, only: %i[new create]

  def routing_page
    routing_page_input = Pages::RoutingPageInput.new({ routing_page_id: params[:routing_page_id], form: current_form })
    render template: "pages/conditions/routing_page", locals: { form: current_form, routing_page_input: }
  end

  def set_routing_page
    routing_page_id = params[:pages_routing_page_input][:routing_page_id]
    routing_page_input = Pages::RoutingPageInput.new({ routing_page_id:, form: current_form })

    if routing_page_input.valid?
      routing_page = current_form.pages.find(routing_page_id)
      redirect_to new_condition_or_show_routes_path(routing_page)
    else
      render template: "pages/conditions/routing_page", locals: { form: current_form, routing_page_input: }, status: :unprocessable_content
    end
  end

  def new
    condition_input = Pages::ConditionsInput.new(form: current_form, page:)
    render template: "pages/conditions/new", locals: { condition_input: }
  end

  def create
    condition_input = Pages::ConditionsInput.new(condition_input_params)

    if condition_input.submit
      if condition_input.create_exit_page?
        redirect_to conditions_exit_page_new_path(current_form.id, page.id, answer_value: condition_input.answer_value)
      else
        # TODO: Route number is hardcoded whilst we can only have one value for it
        # https://trello.com/c/BfkZEIgM/3446-set-route-count-dynamically-instead-of-hard-coding-it
        redirect_to show_routes_path(form_id: current_form.id, page_id: page.id), success: t("banner.success.route_created", route_number: 1)
      end
    else
      render template: "pages/conditions/new", locals: { condition_input: }, status: :unprocessable_content
    end
  end

  def edit
    condition = page.routing_conditions.find(params[:condition_id])

    condition_input = Pages::ConditionsInput.new(form: current_form, page:, record: condition, answer_value: condition.answer_value, goto_page_id: condition.goto_page_id, skip_to_end: condition.skip_to_end).assign_condition_values

    condition_input.check_errors_from_api

    render template: "pages/conditions/edit", locals: { condition_input: }
  end

  def update
    condition = page.routing_conditions.find(params[:condition_id])

    form_params = condition_input_params.merge(record: condition)

    condition_input = Pages::ConditionsInput.new(form_params)

    # Check if we are changing an exit page and should warn that the content will be lost
    if condition.exit_page? && condition_input.goto_page_id != "exit_page"
      return redirect_to confirm_change_exit_page_path(current_form.id, page.id, condition.id, params: { answer_value: condition_input_params[:answer_value], goto_page_id: condition_input_params[:goto_page_id] })
    end

    if condition_input.update_condition
      if condition_input.create_exit_page?
        redirect_to conditions_exit_page_edit_path(current_form.id, page.id, condition.id)
      else
        redirect_to show_routes_path(form_id: current_form.id, page_id: page.id), success: t("banner.success.route_updated", question_number: condition_input.page.position)
      end
    else
      render template: "pages/conditions/edit", locals: { condition_input: }, status: :unprocessable_content
    end
  end

  def delete
    condition = page.routing_conditions.find(params[:condition_id])

    delete_condition_input = Pages::DeleteConditionInput.new(form: current_form, page:, record: condition)

    render template: "pages/conditions/delete", locals: { delete_condition_input: }
  end

  def destroy
    condition = page.routing_conditions.find(params[:condition_id])

    form_params = delete_condition_input_params.merge(record: condition)

    delete_condition_input = Pages::DeleteConditionInput.new(form_params)

    if delete_condition_input.submit
      if delete_condition_input.confirmed?
        redirect_to form_pages_path(current_form.id), success: t("banner.success.route_deleted", question_number: delete_condition_input.page.position)
      else
        redirect_to edit_condition_path(current_form.id, page.id, condition.id)
      end
    else
      render template: "pages/conditions/delete", locals: { delete_condition_input: }, status: :unprocessable_content
    end
  end

  def confirm_delete_exit_page
    condition = page.routing_conditions.find(params[:condition_id])
    delete_exit_page_input = Conditions::DeleteExitPageInput.new

    render template: "pages/conditions/confirm_delete_exit_page", locals: {
      answer_value: params.require(:answer_value),
      goto_page_id: params.require(:goto_page_id),
      exit_page: condition,
      delete_exit_page_input: delete_exit_page_input,
    }
  end

  def update_change_exit_page
    condition = page.routing_conditions.find(params[:condition_id])

    return redirect_to form_pages_path(current_form.id) unless condition.exit_page?

    delete_exit_page_input = Conditions::DeleteExitPageInput.new(delete_exit_page_params)

    unless delete_exit_page_input.valid?
      return render template: "pages/conditions/confirm_delete_exit_page", locals: {
        answer_value: params.require(:answer_value),
        goto_page_id: params.require(:goto_page_id),
        exit_page: condition,
        delete_exit_page_input: delete_exit_page_input,
      }, status: :unprocessable_content
    end

    unless delete_exit_page_input.confirmed?
      return redirect_to edit_condition_path(current_form.id, page.id, condition.id)
    end

    # prepare to update the condition
    condition_input = Pages::ConditionsInput.new(
      answer_value: params.require(:answer_value),
      goto_page_id: params.require(:goto_page_id),
      form: current_form,
      page: page,
      record: condition,
    )

    if condition_input.update_condition
      redirect_to show_routes_path(form_id: current_form.id, page_id: page.id), success: t("banner.success.route_updated", question_number: condition_input.page.position)
    else
      render template: "pages/conditions/edit", locals: { condition_input: }, status: :unprocessable_content
    end
  end

private

  def can_add_page_routing
    authorize current_form, :can_add_page_routing_conditions?

    # currently we can only create one primary condition from a page
    # if there is already a primary condition, redirect to the routes page
    if page.routing_conditions.present?
      redirect_to show_routes_path(form_id: current_form.id, page_id: page.id)
    end
  end

  def condition_input_params
    params.require(:pages_conditions_input).permit(:answer_value, :goto_page_id).merge(form: current_form, page:)
  end

  def delete_condition_input_params
    params.require(:pages_delete_condition_input).permit(:confirm).merge(form: current_form, page:)
  end

  def delete_exit_page_params
    params.require(:conditions_delete_exit_page_input).permit(:confirm)
  end

  def new_condition_or_show_routes_path(page)
    if page.routing_conditions.present?
      return show_routes_path(form_id: current_form.id, page_id: page.id)
    end

    new_condition_path(current_form.id, page.id)
  end
end
