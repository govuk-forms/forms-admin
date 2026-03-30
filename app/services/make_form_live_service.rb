class MakeFormLiveService
  class << self
    def call(**args)
      new(**args)
    end
  end

  def initialize(current_form:, current_user:, language: nil)
    @current_form = current_form
    @current_form_was_live = current_form.is_live?
    @current_form_was_archived = current_form.is_archived?
    @current_live_form = FormDocument::Content.from_form_document(current_form.live_form_document) if current_form.is_live?
    @current_user = current_user
    @language = language
  end

  def make_live
    @current_form.make_live!

    if live_form_submission_email_has_changed
      SubmissionEmailMailer.alert_email_change(
        live_email: @current_live_form.submission_email,
        form_name: @current_live_form.name,
        creator_name: @current_user.name,
        creator_email: @current_user.email,
      ).deliver_now
    end
  end

  def make_language_live
    if @language == "en"
      make_english_live
    else
      make_welsh_live
    end
  end

  def make_english_live
    @current_form.make_english_version_live!

    if live_form_submission_email_has_changed
      SubmissionEmailMailer.alert_email_change(
        live_email: @current_live_form.submission_email,
        form_name: @current_live_form.name,
        creator_name: @current_user.name,
        creator_email: @current_user.email,
      ).deliver_now
    end
  end

  def make_welsh_live
    @current_form.make_welsh_version_live!
  end

  def page_title
    return I18n.t("page_titles.your_form_is_live") if @current_form_was_archived
    return I18n.t("page_titles.your_changes_are_live") if @current_form_was_live
    return I18n.t("page_titles.your_english_form_is_live") if @language == "en"
    return I18n.t("page_titles.your_welsh_form_is_live") if @language == "cy"

    I18n.t("page_titles.your_form_is_live")
  end

  def confirmation_page_body
    return I18n.t("make_changes_live.confirmation.body_html_cy").html_safe if @current_form_was_live && @current_form.has_welsh_translation?
    return I18n.t("make_changes_live.confirmation.body_html").html_safe if @current_form_was_live

    return I18n.t("make_live.confirmation.body_individual_language_html").html_safe if @language.present?
    return I18n.t("make_live.confirmation.body_html_cy").html_safe if @current_form.has_welsh_translation?

    I18n.t("make_live.confirmation.body_html").html_safe
  end

private

  def live_form_submission_email_has_changed
    @current_form_was_live && @current_live_form.submission_email != @current_form.submission_email
  end
end
