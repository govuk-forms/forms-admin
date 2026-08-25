class OrganisationDomainsController < WebController
  after_action :verify_authorized

  def new
    authorize organisation, :can_manage_organisation_domains?

    @domain_input = Organisations::DomainInput.new(organisation:)
  end

  def create
    authorize organisation, :can_manage_organisation_domains?

    @domain_input = Organisations::DomainInput.new(organisation_input_params)

    if @domain_input.submit
      redirect_to organisation_path(organisation), success: "#{@domain_input.domain} has been added to this organisation"
    else
      render :new, status: :unprocessable_entity
    end
  end

private

  def organisation
    @organisation ||= Organisation.find(params[:organisation_id])
  end

  def organisation_input_params
    params.require(:organisations_domain_input).permit(:domain).merge(organisation:)
  end
end
