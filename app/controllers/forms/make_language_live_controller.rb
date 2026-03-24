module Forms
  class MakeLanguageLiveController < FormsController
    def new
      authorize current_form, :can_make_language_live?
      @make_language_live_input = MakeLiveInput.new(form: current_form)

      render "new", status:, locals: { current_form: }
    end

    def create
      authorize current_form, :can_make_language_live?

      @make_language_live_input = MakeLiveInput.new(**make_language_live_input_params)

      return render_new(status: :unprocessable_content) unless @make_language_live_input.valid?
      return redirect_to form_path(@make_language_live_input.form.id) unless @make_language_live_input.confirmed?

      @make_form_live_service = MakeFormLiveService.call(current_form:, current_user:, language: params[:language])
      # TODO: actually make the language live

      @go_to_make_welsh_live_input = GoToMakeWelshLiveInput.new

      render "confirmation", locals: {
        current_form:,
        confirmation_page_title: @make_form_live_service.page_title,
        confirmation_page_body: @make_form_live_service.confirmation_page_body,
        language: params[:language],
      }
    end

  private

    def make_language_live_input_params
      params.require(:forms_make_live_input).permit(:confirm).merge(form: current_form)
    end
  end
end
