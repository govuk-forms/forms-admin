module Account
  class OrganisationsController < WebController
    include AfterSignInPathHelper

    before_action :redirect_if_organisation_exists
    before_action :render_if_no_matches
    skip_before_action :redirect_if_account_not_completed

    def edit
      return redirect_to show_confirm_account_organisation_path if allowed_organisations.one?

      @organisation_input = OrganisationInput.new(user: current_user, allowed_organisations:).assign_form_values
    end

    def update
      @organisation_input = OrganisationInput.new(account_organisation_input_params)

      if @organisation_input.not_listed_selected?
        render :no_matches
      elsif @organisation_input.submit
        redirect_to next_path
      else
        render :edit, status: :unprocessable_content
      end
    end

    def show_confirm
      return redirect_to edit_account_organisation_path unless allowed_organisations.one?

      @confirm_organisation_input = ConfirmOrganisationInput.new(organisation: allowed_organisations.sole)

      render :confirm
    end

    def confirm
      return redirect_to edit_account_organisation_path unless allowed_organisations.one?

      organisation = allowed_organisations.sole
      @confirm_organisation_input = ConfirmOrganisationInput.new(
        confirm_organisation_input_params.merge(organisation: organisation),
      )

      return render :confirm, status: :unprocessable_content if @confirm_organisation_input.invalid?
      return render :no_matches unless @confirm_organisation_input.confirmed?

      current_user.update!(organisation: organisation)
      Rails.logger.info("User chose their organisation", { organisation_id: organisation.id })

      redirect_to next_path
    end

  private

    def account_organisation_input_params
      params.fetch(:account_organisation_input, {}).permit(:organisation_id)
            .merge({ user: current_user, allowed_organisations: })
    end

    def confirm_organisation_input_params
      params.require(:account_confirm_organisation_input).permit(:confirm)
    end

    def redirect_if_organisation_exists
      redirect_to root_path if current_user.organisation.present?
    end

    def render_if_no_matches
      render :no_matches if allowed_organisations.empty?
    end

    def next_path
      after_sign_in_next_path
    end

    def allowed_organisations
      @allowed_organisations ||= if FeatureService.enabled?(:show_relevant_organisations)
                                   Organisation.not_closed.for_domain(current_user.email_domain).order(:name)
                                 else
                                   Organisation.not_closed.order(:name)
                                 end
    end
  end
end
