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

  def delete
    authorize organisation, :can_manage_organisation_domains?

    @organisation_domain = organisation_domain
    @delete_confirmation_input = Organisations::DeleteConfirmationInput.new
  end

  def destroy
    authorize organisation, :can_manage_organisation_domains?

    @organisation_domain = organisation_domain
    @delete_confirmation_input = Organisations::DeleteConfirmationInput.new(delete_confirmation_input_params)

    unless @delete_confirmation_input.valid?
      return render :delete, status: :unprocessable_entity
    end

    unless @delete_confirmation_input.confirmed?
      return redirect_to organisation_path(organisation), status: :see_other
    end

    @organisation_domain.destroy!

    redirect_to organisation_path(organisation), success: "#{@organisation_domain.domain} has been removed from this organisation", status: :see_other
  end

private

  def organisation
    @organisation ||= Organisation.find(params[:organisation_id])
  end

  def organisation_domain
    @organisation_domain ||= organisation.organisation_domains.find(params[:id])
  end

  def organisation_input_params
    params.require(:organisations_domain_input).permit(:domain).merge(organisation:)
  end

  def delete_confirmation_input_params
    params.require(:organisations_delete_confirmation_input).permit(:confirm)
  end
end
