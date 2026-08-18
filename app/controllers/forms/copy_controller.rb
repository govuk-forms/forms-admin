module Forms
  class CopyController < FormsController
    def copy
      authorize current_form, :copy?

      form = if %w[live archived].include? tag
               current_live_or_archived_form
             else
               current_form
             end

      set_back_link(form)

      @copy_input = Forms::CopyInput.new(form: form, tag: tag).assign_form_values

      render :confirm
    end

    def create
      authorize current_form, :copy?
      @copy_input = Forms::CopyInput.new(copy_input_params(current_form))

      if @copy_input.submit
        copied_form = FormCopyService.new(current_form, current_user).copy(tag: @copy_input.tag)
        copied_form.update!(name: @copy_input.name)

        OrgAdminAlertsService.new(form: copied_form, current_user:).new_draft_form_created

        redirect_to form_path(copied_form.id), success: t("banner.success.form.copied")
      else
        set_back_link(current_form)
        render :confirm
      end
    end

  private

    def copy_input_params(form)
      params.require(:forms_copy_input).permit(:name, :tag).merge(form:)
    end

    def tag
      return "draft" if params[:tag].blank?

      params[:tag]
    end

    def set_back_link(form)
      @back_link = if tag == "live"
                     { url: live_form_path(form.id), body: I18n.t("back_link.form_view") }
                   elsif tag == "archived"
                     { url: archived_form_path(form.id), body: I18n.t("back_link.form_view") }
                   else
                     { url: form_path(form.id), body: I18n.t("back_link.form_edit") }
                   end
    end
  end
end
