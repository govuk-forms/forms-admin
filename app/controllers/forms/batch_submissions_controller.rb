module Forms
  class BatchSubmissionsController < FormsController
    def new
      authorize current_form, :can_edit_form?
      @batch_submissions_input = Forms::BatchSubmissionsInput.new(form: current_form).assign_form_values
    end

    def create
      authorize current_form, :can_edit_form?
      @batch_submissions_input = Forms::BatchSubmissionsInput.new(batch_submissions_input_params)

      if @batch_submissions_input.submit
        success_message = success_message(@batch_submissions_input.batch_frequencies, @batch_submissions_input.delivery_configurations_changed?)
        redirect_to form_path(current_form.id), success: success_message
      else
        render :new, status: :unprocessable_content
      end
    end

  private

    def batch_submissions_input_params
      params.require(:forms_batch_submissions_input).permit(batch_frequencies: []).merge(form: current_form)
    end

    def success_message(batch_frequencies, delivery_configurations_changed)
      return nil unless delivery_configurations_changed

      batch_frequencies = Array(batch_frequencies)

      if batch_frequencies.include?("daily") && batch_frequencies.include?("weekly")
        t("banner.success.form.batch_submissions.daily_and_weekly_enabled")
      elsif batch_frequencies.include?("daily")
        t("banner.success.form.batch_submissions.daily_enabled")
      elsif batch_frequencies.include?("weekly")
        t("banner.success.form.batch_submissions.weekly_enabled")
      else
        t("banner.success.form.batch_submissions.disabled")
      end
    end
  end
end
