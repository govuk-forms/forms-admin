module Forms
  class ArchiveWelshController < FormsController
    before_action :check_user_has_permission

    def show
      return redirect_to path_to_form unless has_live_welsh_translation?

      @confirm_archive_welsh_input = ConfirmArchiveWelshInput.new(form: current_form)
    end

    def update
      return redirect_to path_to_form unless has_live_welsh_translation?

      @confirm_archive_welsh_input = ConfirmArchiveWelshInput.new(confirm_archive_welsh_input_params)

      return render :show, status: :unprocessable_content unless @confirm_archive_welsh_input.valid?
      return redirect_to live_form_path(current_form.id) unless user_wants_to_archive_form

      ArchiveFormService.new(form: current_form, current_user: @current_user).archive_welsh_only

      redirect_to live_form_path(current_form.id), success: t("archive_welsh.success")
    end

  private

    def check_user_has_permission
      authorize current_form, :can_view_form?
    end

    def path_to_form
      FormService.new(current_form).path_for_state
    end

    def confirm_archive_welsh_input_params
      params.require(:forms_confirm_archive_welsh_input).permit(:confirm).merge(form: current_form)
    end

    def user_wants_to_archive_form
      @confirm_archive_welsh_input.confirmed?
    end

    def has_live_welsh_translation?
      # We assume all forms have an English version, which must be live.
      # So we check the form is live as well as having a Welsh translation.
      current_form.is_live? && current_form.has_live_welsh_translation?
    end
  end
end
