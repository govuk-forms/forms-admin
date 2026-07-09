class FormTaskListService
  include Rails.application.routes.url_helpers

  attr_reader :task_counts

  class << self
    def call(**args)
      new(**args)
    end
  end

  def initialize(form:, current_user:)
    @current_user = current_user
    @form = form
    @form.set_task_status_service(TaskStatusService.new(form:, current_user:))
    @task_statuses = form.all_task_statuses
    @task_counts = status_counts
  end

  def all_sections
    [
      create_form_section(section_number: 1),
      create_form_optional_subsection,
      how_you_get_completed_forms_section(section_number: 2),
      how_you_get_completed_forms_optional_subsection,
      privacy_and_contact_details_section(section_number: 3),
      translations_section(section_number: 4),
      make_form_live_section(section_number: 5),
    ].compact
  end

private

  def create_or_edit
    return "edit" if @form.is_live?
    return "edit" if @form.is_archived?

    "create"
  end

  def create_form_section(section_number:)
    {
      title: I18n.t("forms.task_list_#{create_or_edit}.create_form_section.title"),
      rows: create_form_section_tasks,
      section_number:,
      subsection: false,
    }
  end

  def create_form_section_tasks
    question_path = if @form.pages.any?
                      form_pages_path(@form.id)
                    else
                      start_new_question_path(@form.id)
                    end
    [
      { task_name: I18n.t("forms.task_list_#{create_or_edit}.create_form_section.name"), path: change_form_name_path(@form.id), status: @task_statuses[:name_status] },
      { task_name: I18n.t("forms.task_list_#{create_or_edit}.create_form_section.questions"), path: question_path, status: @task_statuses[:pages_status] },
      { task_name: I18n.t("forms.task_list_#{create_or_edit}.create_form_section.declaration"), path: declaration_path(@form.id), status: @task_statuses[:declaration_status] },
      { task_name: I18n.t("forms.task_list_#{create_or_edit}.create_form_section.what_happens_next"), path: what_happens_next_path(@form.id), status: @task_statuses[:what_happens_next_status] },
    ]
  end

  def create_form_optional_subsection
    rows = [
      { task_name: I18n.t("forms.task_list_#{create_or_edit}.create_form_optional_subsection.payment_link"), path: payment_link_path(@form.id), status: @task_statuses[:payment_link_status] },
    ]
    if FeatureService.new(group: @form.group).enabled?(:custom_branding)
      rows << { task_name: I18n.t("forms.task_list_#{create_or_edit}.create_form_optional_subsection.brand"), path: form_brand_path(@form.id), status: @task_statuses[:brand_status] }
    end
    if FeatureService.new(group: @form.group).enabled?(:send_filler_answers)
      rows << { task_name: I18n.t("forms.task_list_#{create_or_edit}.create_form_optional_subsection.copy_of_answers"), path: copy_of_answers_path(@form.id), status: @task_statuses[:copy_of_answers_status] }
    end

    {
      title: I18n.t("forms.task_list.optional_tasks_title", count: rows.count),
      rows: rows,
      section_number: nil,
      subsection: true,
    }
  end

  def how_you_get_completed_forms_section(section_number:)
    {
      title: I18n.t("forms.task_list_#{create_or_edit}.how_you_get_completed_forms_section.title"),
      section_number:,
      subsection: false,
      rows: how_you_get_completed_forms_section_tasks,
    }
  end

  def how_you_get_completed_forms_section_tasks
    hint_text = I18n.t("forms.task_list_#{create_or_edit}.how_you_get_completed_forms_section.hint_text_html", submission_email: @form.submission_email) if @form.submission_email.present?
    [{ task_name: I18n.t("forms.task_list_#{create_or_edit}.how_you_get_completed_forms_section.email"), path: submission_email_input_path(@form.id), hint_text:, status: @task_statuses[:submission_email_status] },
     { task_name: I18n.t("forms.task_list_#{create_or_edit}.how_you_get_completed_forms_section.confirm_email"), path: submission_email_code_path(@form.id), status: @task_statuses[:confirm_submission_email_status], active: can_enter_submission_email_code }]
  end

  def how_you_get_completed_forms_optional_subsection
    rows = []
    rows << submission_attachments_task if @form.email?
    rows << batch_submissions_task

    return nil if rows.empty?

    {
      title: I18n.t("forms.task_list.optional_tasks_title", count: rows.count),
      section_number: nil,
      subsection: true,
      rows:,
    }
  end

  def submission_attachments_task
    {
      task_name: I18n.t("forms.task_list_#{create_or_edit}.how_you_get_completed_forms_section.optional_subsection.submission_attachments"),
      path: submission_attachments_path(@form.id),
      status: @task_statuses[:submission_attachments_status],
    }
  end

  def batch_submissions_task
    task_name = I18n.t("forms.task_list_#{create_or_edit}.how_you_get_completed_forms_section.optional_subsection.batch_submissions")

    {
      task_name:,
      path: batch_submissions_path(@form.id),
      status: @task_statuses[:batch_submissions_status],
    }
  end

  def privacy_and_contact_details_section(section_number:)
    {
      title: I18n.t("forms.task_list_#{create_or_edit}.privacy_and_contact_details_section.title"),
      rows: privacy_and_contact_details_section_tasks,
      section_number:,
      subsection: false,
    }
  end

  def privacy_and_contact_details_section_tasks
    [
      { task_name: I18n.t("forms.task_list_#{create_or_edit}.privacy_and_contact_details_section.privacy_policy"), path: privacy_policy_path(@form.id), status: @task_statuses[:privacy_policy_status] },
      { task_name: I18n.t("forms.task_list_#{create_or_edit}.privacy_and_contact_details_section.contact_details"), path: contact_details_path(@form.id), status: @task_statuses[:support_contact_details_status] },
    ]
  end

  def translations_section(section_number:)
    {
      title: I18n.t("forms.task_list_#{create_or_edit}.translations_section.title"),
      rows: translations_section_task,
      section_number:,
      subsection: false,
    }
  end

  def translations_section_task
    [
      { task_name: I18n.t("forms.task_list_#{create_or_edit}.translations_section.add_welsh"), path: welsh_translation_path(@form.id), status: @task_statuses[:welsh_language_status] },
    ]
  end

  def make_form_live_section(section_number:)
    section = {
      title: live_title_name,
      section_number:,
      subsection: false,
    }

    if Pundit.policy(@current_user, @form).can_make_form_live?
      section[:rows] = make_form_live_section_tasks
    else
      section[:body_text] = make_form_live_section_body_text
    end

    section
  end

  def make_form_live_section_body_text
    return inactive_group_message unless @form.group.active?

    I18n.t("forms.task_list_create.make_form_live_section.user_cannot_administer.body_text", group_members_path: group_members_path(@form.group)) unless Pundit.policy(@current_user, @form).can_administer_group?
  end

  def inactive_group_message
    return I18n.t("forms.task_list_create.make_form_live_section.group_not_active.no_org_admin") if @form.group.organisation.admin_users.blank?
    return I18n.t("forms.task_list_create.make_form_live_section.group_not_active.group_admin.body_text", upgrade_path: group_upgrade_url) if Pundit.policy(@current_user, @form).can_administer_group?

    I18n.t("forms.task_list_create.make_form_live_section.group_not_active.group_editor.body_text", group_members_path: group_members_path(@form.group))
  end

  def group_upgrade_url
    return request_upgrade_group_path(@form.group) unless Pundit.policy(@current_user, @form.group).upgrade?

    group_path(@form.group)
  end

  def make_form_live_section_tasks
    [
      share_preview_task,
      (make_live_task unless display_make_languages_live_tasks?),
      (make_only_english_live_task if display_make_languages_live_tasks?),
      (make_only_welsh_live_task if display_make_languages_live_tasks?),
    ].compact
  end

  def share_preview_task
    {
      task_name: share_preview_task_name,
      path: share_preview_path(@form.id),
      status: @task_statuses[:share_preview_status],
      active: @form.pages.any?,
    }
  end

  def make_live_task
    status = @task_statuses[:make_live_status]
    can_make_form_live = status == :not_started

    {
      task_name: live_task_name,
      path: can_make_form_live ? make_live_path(@form.id) : "",
      status: status,
      active: can_make_form_live,
    }
  end

  def make_only_english_live_task
    status = @task_statuses[:make_only_english_live_status]
    can_make_form_live = status == :not_started
    english_changes_to_make_live = @form.is_live? && @form.changed_from_live_version?(language: "en")

    task_name = english_changes_to_make_live ? I18n.t("forms.task_list_edit.make_form_live_section.make_english_form_live") : I18n.t("forms.task_list_create.make_form_live_section.make_english_form_live")

    {
      task_name:,
      path: can_make_form_live ? make_language_live_path(@form.id, language: "en") : "",
      status:,
      active: can_make_form_live,
    }
  end

  def make_only_welsh_live_task
    status = @task_statuses[:make_only_welsh_live_status]
    can_make_form_live = status == :not_started

    {
      task_name: I18n.t("forms.task_list_create.make_form_live_section.make_welsh_form_live"),
      path: can_make_form_live ? make_language_live_path(@form.id, language: "cy") : "",
      status:,
      active: can_make_form_live,
    }
  end

  def display_make_languages_live_tasks?
    @form.live_welsh_form_document.blank? && @form.has_welsh_translation?
  end

  def live_title_name
    return I18n.t("forms.task_list_create.make_form_live_section.title") if @form.is_archived?

    I18n.t("forms.task_list_#{create_or_edit}.make_form_live_section.title")
  end

  def share_preview_task_name
    I18n.t("forms.task_list_#{create_or_edit}.make_form_live_section.share_preview")
  end

  def live_task_name
    return I18n.t("forms.task_list_create.make_form_live_section.make_live") if @form.is_archived?

    I18n.t("forms.task_list_#{create_or_edit}.make_form_live_section.make_live")
  end

  def statuses_by_user
    statuses = @task_statuses

    unless Pundit.policy(@current_user, @form).can_make_form_live?
      statuses.delete(:share_preview_status)
      statuses.delete(:make_live_status)
    end

    statuses
  end

  def status_counts
    filtered_statuses = statuses_by_user.compact
    remove_optional_statuses(filtered_statuses)

    { completed: filtered_statuses.count { |_key, value| value == :completed },
      total: filtered_statuses.count }
  end

  def remove_optional_statuses(statuses)
    statuses.delete(:payment_link_status)
    statuses.delete(:brand_status)
    statuses.delete(:copy_of_answers_status)
    statuses.delete(:submission_attachments_status)
    statuses.delete(:batch_submissions_status)
  end

  def can_enter_submission_email_code
    @form.email_confirmation_status == :sent
  end
end
