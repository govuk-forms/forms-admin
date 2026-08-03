module Forms
  class ContactDetailsController < FormsController
    def new
      authorize current_form, :can_view_form?
      @contact_details_input = ContactDetailsInput.new(form: current_form).assign_form_values
    end

    def create
      authorize current_form, :can_view_form?
      @contact_details_input = ContactDetailsInput.new(**contact_details_input_params)

      if @contact_details_input.submit
        redirect_to form_path(@contact_details_input.form.id), success: t("banner.success.form.support_details_saved")
      else
        render :new, status: :unprocessable_content
      end
    end

  private

    def contact_details_input_params
      params.require(:forms_contact_details_input).permit(:email, :phone, :link_href, :link_text, contact_details_supplied: []).merge(form: current_form)
    end
  end
end
