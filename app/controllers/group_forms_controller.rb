class GroupFormsController < WebController
  before_action :set_group
  after_action :verify_authorized

  # GET /groups/:group_id/forms/new
  def new
    @group_form = GroupForm.new(group: @group)
    authorize @group_form

    @name_input = Forms::NameInput.new
  end

  # POST /groups/:group_id/forms
  def create
    @group_form = GroupForm.new(group: @group)
    authorize @group_form

    @name_input = Forms::NameInput.new(name_input_params)

    if @name_input.valid?
      @form = CreateFormService.new.create!(creator: @current_user, group: @group, name: @name_input.name)
      OrgAdminAlertsService.new(form: @form, current_user:).new_draft_form_created

      redirect_to form_path(@form.id)
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    raise NotFoundError unless set_group_form

    @form = Form.find(params[:id])
    @group_select = Forms::GroupSelect.new(group: @group, form: @form)
    @group_select_presenter = Forms::GroupSelectPresenter.call(group: @group, groups: @group_select.groups, form: @form)
  end

  def update
    raise NotFoundError unless set_group_form

    @form = Form.find(params[:id])
    @group_select = Forms::GroupSelect.new(group_select_params.merge(form: @form))

    if @group_select.valid?
      # The receiving group must be one the user could have selected: in the
      # same organisation as the current group, and active if the form is live
      receiving_group = Forms::GroupSelect.new(group: @group, form: @form).groups.find_by(external_id: @group_select.group)

      if receiving_group
        GroupFormsService.new(group: receiving_group, form: @form, current_user: @current_user, old_group: @group).move_form_to(receiving_group)
        success_message = t(".success", form_name: @form.name, receiving_group_name: receiving_group.name)

        redirect_to @group, success: success_message, status: :see_other
      else
        @group_select = Forms::GroupSelect.new(group: @group, form: @form)
        @group_select_presenter = Forms::GroupSelectPresenter.call(group: @group, groups: @group_select.groups, form: @form)
        @group_select.errors.add(:group, :gone)

        render :edit, status: :unprocessable_content
      end
    else
      @group_select = Forms::GroupSelect.new(group: @group, form: @form)
      @group_select_presenter = Forms::GroupSelectPresenter.call(group: @group, groups: @group_select.groups, form: @form)
      @group_select.errors.add(:group, :blank) if group_select_params[:selected_group].blank?

      render :edit, status: :unprocessable_content
    end
  end

private

  def set_group
    @group = Group.find_by!(external_id: params[:group_id])
  end

  def group_select_params
    params.require(:forms_group_select).permit(:group)
  end

  def name_input_params
    params.require(:forms_name_input).permit(:name)
  end

  def set_group_form
    @group_form = GroupForm.find_by(form_id: params[:id])
    authorize @group_form
    @group_form.group_id == @group.id
  end
end
