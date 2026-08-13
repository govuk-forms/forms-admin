class AdminAlerts::DraftCreatedMailer < GovukNotifyRails::Mailer
  include Rails.application.routes.url_helpers
  def new_draft_form_created(form:, user:, to_email:)
    set_template(Settings.govuk_notify.admin_alerts.new_draft_form_created_template_id)
    send_mail(to_email:, personalisation: {
      form_name: form.name,
      form_link: form_url(form),
      group_name: form.group.name,
      user_name: user.name,
      user_email: user.email,
    })
  end

  def copied_draft_form_created(form:, copied_from_form:, user:, to_email:)
    set_template(Settings.govuk_notify.admin_alerts.copied_draft_form_created_template_id)
    send_mail(to_email:, personalisation: {
      form_name: form.name,
      form_link: form_url(form),
      copied_from_form_name: copied_from_form.name,
      copied_from_form_link: form_url(copied_from_form),
      group_name: form.group.name,
      user_name: user.name,
      user_email: user.email,
    })
  end

  def new_archived_form_draft_created(form:, user:, to_email:)
    set_template(Settings.govuk_notify.admin_alerts.new_archived_form_draft_created_template_id)
    send_mail(to_email:, personalisation: {
      form_name: form.name,
      form_link: form_url(form),
      archived_form_name: form.latest_form_document.content["name"],
      archived_form_link: archived_form_url(form),
      group_name: form.group.name,
      user_name: user.name,
      user_email: user.email,
    })
  end

  def new_live_form_draft_created(form:, user:, to_email:)
    set_template(Settings.govuk_notify.admin_alerts.new_live_form_draft_created_template_id)
    send_mail(to_email:, personalisation: {
      form_name: form.name,
      form_link: form_url(form),
      live_form_name: form.latest_form_document.content["name"],
      live_form_link: live_form_url(form),
      group_name: form.group.name,
      user_name: user.name,
      user_email: user.email,
    })
  end

private

  def send_mail(to_email:, personalisation:)
    set_personalisation(**personalisation)

    mail(to: to_email)
  end
end
