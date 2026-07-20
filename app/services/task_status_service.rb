class TaskStatusService
  def initialize(form:, current_user:)
    @form = form
    @current_user = current_user
  end

  def mandatory_tasks_completed?(ignore_missing_welsh: false)
    all_incomplete_tasks(ignore_missing_welsh:).empty?
  end

  def all_incomplete_tasks(ignore_missing_welsh: false)
    keys_to_skip = [(:missing_welsh_translations if ignore_missing_welsh)]
    values_to_skip = %i[completed optional]
    {
      missing_pages: pages_status,
      missing_what_happens_next: what_happens_next_status,
      missing_privacy_policy_url: privacy_policy_status,
      missing_contact_details: support_contact_details_status,
      share_preview_not_completed: share_preview_status,
      missing_welsh_translations: welsh_language_status,
      missing_submission_email: submission_email_status,
    }.reject { |k, v| keys_to_skip.include?(k) || values_to_skip.include?(v) }.keys
  end

  def all_task_statuses
    {
      name_status:,
      pages_status:,
      declaration_status:,
      what_happens_next_status:,
      payment_link_status:,
      brand_status:,
      copy_of_answers_status:,
      privacy_policy_status:,
      support_contact_details_status:,
      submission_attachments_status:,
      batch_submissions_status:,
      share_preview_status:,
      make_live_status:,
      make_only_english_live_status:,
      make_only_welsh_live_status:,
      welsh_language_status:,
      submission_email_status:,
      confirm_submission_email_status:,
    }
  end

  def incomplete_email_tasks
    {
      missing_submission_email: submission_email_status,
    }.reject { |_k, v| v == :completed }.keys
  end

  def email_task_statuses
    {
      submission_email_status:,
      confirm_submission_email_status:,
    }
  end

private

  def name_status
    :completed
  end

  def pages_status
    return :completed if @form.question_section_completed && @form.pages.any?
    return :in_progress if @form.pages.any?

    :not_started
  end

  def declaration_status
    return :completed if @form.declaration_section_completed
    return :in_progress if @form.declaration_markdown.present?

    :not_started
  end

  def what_happens_next_status
    return :completed if @form.what_happens_next_markdown.present?

    :not_started
  end

  def payment_link_status
    return :completed if @form.payment_url.present?

    :optional
  end

  def brand_status
    return :completed if @form.brand_id.present?

    :optional
  end

  def copy_of_answers_status
    return :completed if @form.send_copy_of_answers_enabled?

    :optional
  end

  def privacy_policy_status
    return :completed if @form.privacy_policy_url.present?

    :not_started
  end

  def support_contact_details_status
    return :completed if @form.support_email.present? || @form.support_phone.present? || (@form.support_url_text.present? && @form.support_url)

    :not_started
  end

  def welsh_language_status
    return :optional unless @form.available_languages.include?("cy")
    return :in_progress if welsh_translations_invalid
    return :completed if @form.welsh_completed?

    :in_progress
  end

  def submission_attachments_status
    return :completed if @form.email? && @form.submission_format.any?

    :optional
  end

  def batch_submissions_status
    return :completed if @form.send_daily_submission_batch || @form.send_weekly_submission_batch

    :optional
  end

  def share_preview_status
    return :cannot_start unless @form.pages.any?
    return :completed if @form.share_preview_completed?

    :not_started
  end

  def make_live_status
    return make_live_status_for_draft if @form.has_draft_version
    return :not_started if @form.has_been_archived

    :completed if @form.has_live_version
  end

  def make_only_english_live_status
    return :completed if @form.has_live_version && !@form.changed_from_live_version?(language: "en")
    return :not_started if @form.can_make_language_live?(language: "en")

    :cannot_start
  end

  def make_only_welsh_live_status
    return :not_started if @form.can_make_language_live?(language: "cy")
    return :completed if @form.live_welsh_form_document.present?

    :cannot_start
  end

  def make_live_status_for_draft
    # If the form has a live Welsh version, we ignore missing Welsh translations
    # and show the make live task and link. In this case, we will show a warning
    # message on the make live page asking the user to update the Welsh before
    # the form can be made live.
    ignore_missing_welsh = @form.live_welsh_form_document.present?
    mandatory_tasks_completed?(ignore_missing_welsh:) ? :not_started : :cannot_start
  end

  def welsh_translations_invalid
    @welsh_translations_invalid ||= begin
      translation_input = Forms::WelshTranslationInput.new(form: @form, mark_complete: true, current_user: @current_user).assign_form_values
      translation_input.invalid?
    end
  end

  def submission_email_status
    {
      email_set_without_confirmation: :completed,
      not_started: :not_started,
      sent: :in_progress,
      confirmed: :completed,
    }[@form.email_confirmation_status]
  end

  def confirm_submission_email_status
    {
      email_set_without_confirmation: :completed,
      not_started: :cannot_start,
      sent: :not_started,
      confirmed: :completed,
    }[@form.email_confirmation_status]
  end
end
