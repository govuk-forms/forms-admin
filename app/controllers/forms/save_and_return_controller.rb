module Forms
  class SaveAndReturnController < FormsController
    before_action :check_user_has_permission
    before_action :check_feature_flag

    def new
      @save_and_return_input = SaveAndReturnInput.new(form: current_form).assign_form_values
    end

    def create
      @save_and_return_input = SaveAndReturnInput.new(save_and_return_input_params)

      if @save_and_return_input.submit
        redirect_to form_path(current_form.id), success: success_message
      else
        render :new, status: :unprocessable_content
      end
    end

  private

    def check_user_has_permission
      authorize current_form, :can_view_form?
    end

    def check_feature_flag
      raise NotFoundError unless FeatureService.new(group: current_form.group).enabled?(:save_and_return)
    end

    def save_and_return_input_params
      params.require(:forms_save_and_return_input).permit(:save_and_return).merge(form: current_form)
    end

    def success_message
      return nil unless current_form.save_and_return_previously_changed?

      if current_form.save_and_return.to_sym == :enabled
        t("banner.success.form.save_and_return_enabled")
      else
        t("banner.success.form.save_and_return_disabled")
      end
    end
  end
end
