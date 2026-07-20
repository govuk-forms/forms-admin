module Forms
  class BrandController < FormsController
    before_action :check_user_has_permission
    before_action :check_feature_flag

    def new
      @brand_input = BrandInput.new(form: current_form).assign_form_values
    end

    def create
      @brand_input = BrandInput.new(brand_input_params)
      previous_brand_id = current_form.brand_id

      if @brand_input.submit
        success_message = success_message(previous_brand_id, @brand_input.form.brand_id)
        redirect_to form_path(@brand_input.form.id), success: success_message
      else
        render :new, status: :unprocessable_content
      end
    end

  private

    def check_user_has_permission
      authorize current_form, :can_view_form?
    end

    def check_feature_flag
      raise NotFoundError unless FeatureService.new(group: current_form.group).enabled?(:custom_branding)
    end

    def brand_input_params
      params.require(:forms_brand_input).permit(:brand_id).merge(form: current_form)
    end

    def success_message(previous_brand_id, new_brand_id)
      return t("banner.success.form.brand_saved") if new_brand_id.present? && new_brand_id != previous_brand_id
      return t("banner.success.form.brand_removed") if new_brand_id.blank? && previous_brand_id.present?

      nil
    end
  end
end
