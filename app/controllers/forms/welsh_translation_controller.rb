module Forms
  class WelshTranslationController < FormsController
    def new
      authorize current_form, :can_edit_form?

      @welsh_translation_input = WelshTranslationInput.new(form: form_with_pages_and_conditions).assign_form_values
      @table_presenter = Forms::TranslationTablePresenter.new
    end

    def create
      authorize current_form, :can_edit_form?

      @welsh_translation_input = WelshTranslationInput.new(welsh_translation_params)
      @table_presenter = Forms::TranslationTablePresenter.new

      if @welsh_translation_input.blanked?
        # if all fields are empty we delete the welsh translation
        @delete_welsh_translation_input = Forms::DeleteWelshTranslationInput.new(form: current_form)
        if @delete_welsh_translation_input.submit_without_confirm
          redirect_to form_path(@welsh_translation_input.form), success: t("forms.welsh_translation.destroy.success")
        end
      elsif @welsh_translation_input.submit
        success_message = if @welsh_translation_input.mark_complete == "true"
                            t("banner.success.form.welsh_translation_saved_and_completed")
                          else
                            t("banner.success.form.welsh_translation_saved")
                          end

        redirect_to form_path(@welsh_translation_input.form), success: success_message
      else
        render :new, status: :unprocessable_content
      end
    end

    def delete
      authorize current_form, :can_edit_form?

      @delete_welsh_translation_input = Forms::DeleteWelshTranslationInput.new(form: current_form)
    end

    def destroy
      authorize current_form, :can_edit_form?

      @delete_welsh_translation_input = Forms::DeleteWelshTranslationInput.new(delete_welsh_translation_params)

      if @delete_welsh_translation_input.submit
        if @delete_welsh_translation_input.confirmed?
          redirect_to form_path(@delete_welsh_translation_input.form), success: t(".success")
        else
          redirect_to welsh_translation_path(@delete_welsh_translation_input.form)
        end
      else
        render :delete, status: :unprocessable_content
      end
    end

    def render_preview
      authorize current_form, :can_view_form?

      render json: { preview_html:, errors: [] }.to_json
    end

    def download
      authorize current_form, :can_edit_form?

      form_content_service = WelshCsvService.new(form_with_pages_and_conditions)

      send_data form_content_service.as_csv,
                type: "text/csv; charset=iso-8859-1",
                disposition: "attachment; filename=#{form_content_service.filename}"
    end

  private

    def preview_html
      return t("markdown_editor.no_markdown_content_html") if params[:markdown].blank?

      GovukFormsMarkdown.render(params[:markdown], locale: "cy")
    end

    def welsh_translation_params
      params.require(:forms_welsh_translation_input).permit(
        *WelshTranslationInput.attribute_names,
        page_translations_attributes: [
          *WelshPageTranslationInput.attribute_names,
          { selection_options_cy_attributes: %i[id name_cy] },
          { condition_translations_attributes: WelshConditionTranslationInput.attribute_names },
        ],
      ).merge(form: current_form)
    end

    def delete_welsh_translation_params
      params.require(:forms_delete_welsh_translation_input).permit(:confirm).merge(form: current_form)
    end

    def form_with_pages_and_conditions
      Form.includes(pages: [:routing_conditions]).find(current_form.id)
    end
  end
end
