class FormsController < WebController
  before_action :load_form
  after_action :verify_authorized
  after_action :alert_org_admins_if_draft_created

  attr_reader :current_form

  def current_live_form
    @current_live_form ||= FormDocument::Content.from_form_document(current_form.live_form_document)
  end

  def current_live_welsh_form
    @current_live_welsh_form ||= FormDocument::Content.from_form_document(current_form.live_welsh_form_document)
  end

  def current_archived_form
    @current_archived_form ||= FormDocument::Content.from_form_document(current_form.archived_form_document)
  end

  def current_archived_welsh_form
    @current_archived_welsh_form ||= FormDocument::Content.from_form_document(current_form.archived_welsh_form_document)
  end

private

  def load_form
    @current_form = Form.find(params[:form_id])
    @current_form.set_task_status_service(TaskStatusService.new(form: @current_form))
    @initial_form_state = @current_form.state
  end

  def alert_org_admins_if_draft_created
    return if current_form.destroyed?
    return unless @current_form.reload.draft_created?(@initial_form_state)

    OrgAdminAlertsService.new(form: current_form, current_user:).draft_of_existing_form_created
  end
end
