module Forms
  class MakeLanguageLiveController < FormsController
    def new
      authorize current_form, :can_make_language_live?
      return redirect_to form_path(form_id: current_form.id) unless current_form.can_make_language_live?(language: params[:language])

      @make_language_live_input = MakeLiveInput.new(form: current_form)

      render_new
    end

    def create
      authorize current_form, :can_make_language_live?

      @make_language_live_input = MakeLiveInput.new(**make_language_live_input_params)

      return redirect_to form_path(@make_language_live_input.form.id) unless @make_language_live_input.confirmed?
      return render_new(status: :unprocessable_content) unless @make_language_live_input.valid?

      return redirect_to form_path(form_id: current_form.id) unless current_form.can_make_language_live?(language: params[:language])

      @make_form_live_service = MakeFormLiveService.call(current_form:, current_user:, language: params[:language])
      @make_form_live_service.make_language_live

      @go_to_make_welsh_live_input = GoToMakeWelshLiveInput.new

      redirect_to make_language_live_show_confirmation_path
    end

    def show_confirmation
      authorize current_form, :can_make_language_live?

      @make_form_live_service = MakeFormLiveService.call(current_form:, current_user:, language: params[:language])

      @go_to_make_welsh_live_input = GoToMakeWelshLiveInput.new

      render "confirmation", locals: {
        current_form:,
        confirmation_page_title: @make_form_live_service.page_title,
        confirmation_page_body: @make_form_live_service.confirmation_page_body,
        language: params[:language],
      }
    end

    def submit_confirmation
      authorize current_form, :can_make_language_live?

      @go_to_make_welsh_live_input = GoToMakeWelshLiveInput.new(**go_to_make_welsh_live_input_params)

      if @go_to_make_welsh_live_input.confirmed?
        redirect_to make_language_live_path(language: "cy")
      else
        redirect_to form_path
      end
    end

  private

    def make_language_live_input_params
      params.require(:forms_make_live_input).permit(:confirm).merge(form: current_form)
    end

    def render_new(status: :ok)
      render "new", status:, locals: { current_form:, language: params[:language] }
    end

    def go_to_make_welsh_live_input_params
      params.require(:forms_go_to_make_welsh_live_input).permit(:confirm)
    end
  end
end
