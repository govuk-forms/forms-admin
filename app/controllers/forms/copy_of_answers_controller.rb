module Forms
  class CopyOfAnswersController < FormsController
    before_action :check_user_has_permission

    def new
      @copy_of_answers_input = Forms::CopyOfAnswersInput.new(form: current_form).assign_form_values
    end

    def create
      @copy_of_answers_input = Forms::CopyOfAnswersInput.new(copy_of_answers_input_params)

      if @copy_of_answers_input.submit
        redirect_to form_path(current_form.id), success: success_message
      else
        render :new, status: :unprocessable_content
      end
    end

  private

    def check_user_has_permission
      authorize current_form, :can_view_form?
    end

    def copy_of_answers_input_params
      params.require(:forms_copy_of_answers_input).permit(:send_copy_of_answers).merge(form: current_form)
    end

    def success_message
      return nil unless current_form.send_copy_of_answers_previously_changed?

      if current_form.send_copy_of_answers.to_sym == :enabled
        t("banner.success.form.copy_of_answers_enabled")
      else
        t("banner.success.form.copy_of_answers_disabled")
      end
    end
  end
end
