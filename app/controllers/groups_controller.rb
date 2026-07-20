class GroupsController < WebController
  before_action :set_group, except: %i[index new create confirm_new confirm_new_submit]
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  # GET /groups
  def index
    if @current_user.super_admin?
      @search_input = OrganisationSearchInput.new({ organisation_id: @current_user.organisation_id }.merge(search_params))

      @active_groups = policy_scope(Group).where(organisation_id: @search_input.organisation_id).active
      @upgrade_requested_groups = policy_scope(Group).where(organisation_id: @search_input.organisation_id).upgrade_requested
      @trial_groups = policy_scope(Group).where(organisation_id: @search_input.organisation_id).trial
      @organisation = @search_input.organisation
    else
      @active_groups = policy_scope(Group).active
      @upgrade_requested_groups = policy_scope(Group).upgrade_requested
      @trial_groups = policy_scope(Group).trial
      @organisation = @current_user.organisation
    end
  end

  # GET /groups/1
  def show
    authorize @group

    forms = @group.forms
    @form_list_presenter = FormListPresenter.call(forms:, group: @group, can_admin: @current_user.can_administer_org?(@group.organisation)) unless forms.empty?
  end

  def confirm_new
    authorize Group, :new?
    @confirm_new_input = Groups::ConfirmNewInput.new
    @organisation = @current_user.organisation
  end

  def confirm_new_submit
    authorize Group, :new?
    @confirm_new_input = Groups::ConfirmNewInput.new(confirm_new_input_params)
    @organisation = @current_user.organisation

    if @confirm_new_input.invalid?
      return render :confirm_new, status: :unprocessable_content
    end

    if @confirm_new_input.confirmed?
      redirect_to new_group_path
    else
      redirect_to groups_path
    end
  end

  # GET /groups/new
  def new
    @group = Group.new
    authorize @group
  end

  # GET /groups/1/edit
  def edit
    authorize @group
  end

  # POST /groups
  def create
    @group = Group.new(group_params.merge({ creator: @current_user }))
    @group.organisation = current_user.organisation
    @group.memberships.build(user: current_user, added_by: current_user, role: :group_admin)

    authorize @group

    if @group.save
      redirect_to @group
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /groups/1
  def update
    authorize @group

    @group.assign_attributes(group_params)

    authorize @group, :move? if @group.organisation_id_changed?

    if @group.active?
      success_message = t("groups.success_messages.update") if @group.changed.include?("name")
      success_message = t("groups.success_messages.move", org_name: @group.organisation.name) if @group.changed.include?("organisation_id")
    else
      success_message = nil
    end

    if @group.save
      redirect_to @group, success: success_message, status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def move
    authorize @group

    @search_input = OrganisationSearchInput.new({ organisation_id: @group.organisation_id }.merge(search_params))
    render :move
  end

  # GET /groups/1/feature-flags
  def feature_flags
    authorize @group, :manage_feature_flags?

    @feature_flags_input = Groups::FeatureFlagsInput.new(group: @group).assign_group_values
  end

  # POST /groups/1/feature-flags
  def update_feature_flags
    authorize @group, :manage_feature_flags?

    @feature_flags_input = Groups::FeatureFlagsInput.new(feature_flags_input_params)

    if @feature_flags_input.submit
      success_message = t("groups.success_messages.feature_flags") if @feature_flags_input.flags_changed?
      redirect_to @group, success: success_message, status: :see_other
    else
      render :feature_flags, status: :unprocessable_content
    end
  end

  # GET /groups/1/delete
  def delete
    authorize @group

    @delete_confirmation_input = Groups::DeleteConfirmationInput.new
  end

  # DELETE /groups/1
  def destroy
    authorize @group

    @delete_confirmation_input = Groups::DeleteConfirmationInput.new(delete_confirmation_input_params)

    unless @delete_confirmation_input.valid?
      return render :delete, status: :unprocessable_content
    end

    unless @delete_confirmation_input.confirmed?
      return redirect_to groups_path, status: :see_other
    end

    begin
      @group.destroy!
    rescue ActiveRecord::DeleteRestrictionError
      @delete_confirmation_input.errors.add(:confirm, :group_has_forms)
      return render :delete, status: :unprocessable_content
    end

    GroupService.new(group: @group, current_user: @current_user).send_group_deleted_emails

    redirect_to groups_path, success: t(".success", group_name: @group.name), status: :see_other
  end

  def confirm_upgrade
    authorize @group, :upgrade?
    @confirm_upgrade_input = Groups::ConfirmUpgradeInput.new
  end

  def upgrade
    authorize @group

    @confirm_upgrade_input = Groups::ConfirmUpgradeInput.new(confirm_upgrade_input_params)
    return render :confirm_upgrade, status: :unprocessable_content unless @confirm_upgrade_input.valid?
    return redirect_to @group unless @confirm_upgrade_input.confirmed?

    GroupService.new(group: @group, current_user: @current_user, host: request.host).upgrade_group

    redirect_to @group, success: t("groups.success_messages.upgrade"), status: :see_other
  end

  def confirm_upgrade_request
    authorize @group, :request_upgrade?
  end

  def request_upgrade
    authorize @group, :request_upgrade?

    GroupService.new(group: @group, current_user: @current_user, host: request.host).request_upgrade

    render :upgrade_requested
  end

  def review_upgrade
    authorize @group, :review_upgrade?
    @confirm_upgrade_input = Groups::ConfirmUpgradeInput.new
  end

  def submit_review_upgrade
    authorize @group, :review_upgrade?

    @confirm_upgrade_input = Groups::ConfirmUpgradeInput.new(confirm_upgrade_input_params)

    return render :review_upgrade, status: :unprocessable_content unless @confirm_upgrade_input.valid?

    group_service = GroupService.new(group: @group, current_user: @current_user, host: request.host)
    if @confirm_upgrade_input.confirmed?
      group_service.upgrade_group
      redirect_to @group, success: t("groups.success_messages.upgrade"), status: :see_other
    else
      group_service.reject_upgrade
      redirect_to @group, status: :see_other
    end
  end

private

  # Use callbacks to share common setup or constraints between actions.
  def set_group
    @group = Group.find_by!(external_id: params[:id])
  end

  # Only allow a list of trusted parameters through.
  def group_params
    params.require(:group).permit(:name, :organisation_id)
  end

  def feature_flags_input_params
    # When every flag is already enabled the form has no enabled inputs, so the
    # input params may be missing entirely.
    params.fetch(:groups_feature_flags_input, {}).permit(*Group.feature_flag_attributes).merge(group: @group)
  end

  def confirm_upgrade_input_params
    params.require(:groups_confirm_upgrade_input).permit(:confirm)
  end

  def delete_confirmation_input_params
    params.require(:groups_delete_confirmation_input).permit(:confirm)
  end

  def search_params
    params[:search]&.permit(:organisation_id) || {}
  end

  def confirm_new_input_params
    params.require(:groups_confirm_new_input).permit(:confirm)
  end
end
