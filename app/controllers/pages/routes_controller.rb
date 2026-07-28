class Pages::RoutesController < PagesController
  def show
    route_summary_card_data_presenter = RouteSummaryCardDataPresenter.new(form: current_form, page:)

    render locals: { current_form:, page:, route_summary_card_data_presenter: }
  end

  def delete
    @delete_confirmation_input = Pages::Routes::DeleteConfirmationInput.new
    render locals: { current_form:, page:, delete_confirmation_input: @delete_confirmation_input }
  end

  def destroy
    @delete_confirmation_input = Pages::Routes::DeleteConfirmationInput.new(delete_confirmation_input_params)

    if @delete_confirmation_input.submit
      if @delete_confirmation_input.confirmed?
        return redirect_to form_pages_path, success: t("banner.success.page_routes_deleted", question_number: current_form.page_number(page))
      end
    else
      return render :delete, locals: { current_form:, page:, delete_confirmation_input: @delete_confirmation_input }, status: :unprocessable_content
    end

    redirect_to show_routes_path(form_id: current_form.id, page_id: page.id)
  end

private

  def delete_confirmation_input_params
    params.require(:pages_routes_delete_confirmation_input).permit(:confirm).merge(form: current_form, page: page)
  end
end
