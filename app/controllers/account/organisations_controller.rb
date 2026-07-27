module Account
  class OrganisationsController < WebController
    include AfterSignInPathHelper

    before_action :redirect_if_organisation_exists
    skip_before_action :redirect_if_account_not_completed

    def edit
      @organisation_input = OrganisationInput.new(user: current_user, allowed_organisations:).assign_form_values
    end

    def update
      @organisation_input = OrganisationInput.new(account_organisation_input_params)

      if @organisation_input.not_listed_selected?
        render :not_listed
      elsif @organisation_input.submit
        redirect_to next_path
      else
        render :edit, status: :unprocessable_content
      end
    end

  private

    def account_organisation_input_params
      params.fetch(:account_organisation_input, {}).permit(:organisation_id)
            .merge({ user: current_user, allowed_organisations: })
    end

    def redirect_if_organisation_exists
      redirect_to root_path if current_user.organisation.present?
    end

    def next_path
      after_sign_in_next_path
    end

    def allowed_organisations
      if FeatureService.enabled?(:show_relevant_organisations)
        Organisation.not_closed.for_domain(current_user.email_domain).order(:name)
      else
        Organisation.not_closed.order(:name)
      end
    end
  end
end
