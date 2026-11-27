module Account
  class NamesController < WebController
    include AfterSignInPathHelper
    include PendingUserAccountSetup

    before_action :redirect_if_name_exists

    def edit
      @name_input = NameInput.new(pending_user:).assign_form_values
    end

    def update
      @name_input = NameInput.new(account_name_input_params)

      if @name_input.submit
        complete_account_setup_if_ready
        redirect_to next_path
      else
        render :edit, status: :unprocessable_content
      end
    end

    def account_name_input_params
      params.require(:account_name_input).permit(:name).merge(pending_user:)
    end

  private

    def redirect_if_name_exists
      redirect_to root_path if pending_user.name.present?
    end
  end
end
