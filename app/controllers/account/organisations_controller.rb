module Account
  class OrganisationsController < WebController
    include AfterSignInPathHelper

    before_action :redirect_if_organisation_exists
    skip_before_action :redirect_if_account_not_completed

    def edit
      @organisations = Organisation.for_email(current_user.email).order(:name)

      if @organisations.empty?
        render :unsupported_email
        return
      end

      @organisation_input = OrganisationInput.new(user: current_user).assign_form_values
    end

    def update
      @organisation_input = OrganisationInput.new(account_organisation_input_params(current_user))

      if @organisation_input.submit
        redirect_to next_path
      else
        render :edit, status: :unprocessable_content
      end
    end

    def account_organisation_input_params(user)
      params.require(:account_organisation_input).permit(:organisation_id).merge(user:)
    end

  private

    def redirect_if_organisation_exists
      redirect_to root_path if current_user.organisation.present?
    end

    def next_path
      after_sign_in_next_path
    end
  end
end
