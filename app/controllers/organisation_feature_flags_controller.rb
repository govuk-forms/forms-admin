class OrganisationFeatureFlagsController < WebController
  # Authorise before looking up the organisation, so users who cannot manage
  # feature flags cannot tell which organisations exist.
  before_action { authorize Organisation, :can_manage_organisation_feature_flags? }
  after_action :verify_authorized

  def edit
    @feature_flags_input = FeatureFlagsInput.new(record: organisation)
  end

  def update
    @feature_flags_input = FeatureFlagsInput.new(record: organisation, submitted: feature_flags_input_params)

    if @feature_flags_input.submit
      success_message = t(".success") if @feature_flags_input.flags_changed?
      redirect_to organisation_path(organisation), success: success_message, status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

private

  def organisation
    @organisation ||= Organisation.find(params[:organisation_id])
  end

  def feature_flags_input_params
    # When every flag is already enabled the form has no enabled inputs, so the
    # input params may be missing entirely. The input only reads the feature flag
    # attributes, so there is nothing to permit here.
    params.fetch(:feature_flags_input, {})
  end
end
