class OrganisationBrandsController < WebController
  after_action :verify_authorized

  def new
    authorize organisation, :can_manage_organisation_brands?

    @brand_input = Organisations::BrandInput.new(organisation:)
  end

  def create
    authorize organisation, :can_manage_organisation_brands?

    @brand_input = Organisations::BrandInput.new(brand_input_params)

    if @brand_input.submit
      redirect_to organisation_path(organisation), success: t(".success", brand_name: @brand_input.brand.name)
    else
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    authorize organisation, :can_manage_organisation_brands?

    organisation_brand = organisation.organisation_brands.find_by!(brand_id: params[:id])
    organisation_brand.destroy!

    redirect_to organisation_path(organisation), success: t(".success", brand_name: organisation_brand.brand.name)
  end

private

  def organisation
    @organisation ||= Organisation.find(params[:organisation_id])
  end

  def brand_input_params
    params.require(:organisations_brand_input).permit(:brand_id).merge(organisation:).tap do |p|
      clear_param_if_autocomplete_empty(p, :brand_id, params.dig(:organisations_brand_input, :brand_id_raw))
    end
  end
end
