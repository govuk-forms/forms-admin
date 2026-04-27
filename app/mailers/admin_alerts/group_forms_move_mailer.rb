class AdminAlerts::GroupFormsMoveMailer < GovukNotifyRails::Mailer
  def form_moved_email_org_admin(...)
    set_template(Settings.govuk_notify.admin_alerts.group_form_moved_org_admin_template_id)

    form_moved_email(...)
  end

  def form_moved_email_group_admin(...)
    set_template(Settings.govuk_notify.admin_alerts.group_form_moved_group_admin_editor_template_id)

    form_moved_email(...)
  end

  def form_moved_email(to_email:, form_name:, old_group_name:, new_group_name:, org_admin_email:, org_admin_name:, group_active:)
    if group_active
      group_active_text = "yes"
      group_trial_text = "no"
    else
      group_active_text = "no"
      group_trial_text = "yes"
    end

    set_personalisation(
      form_name:,
      old_group_name:,
      new_group_name:,
      org_admin_email:,
      org_admin_name:,
      group_active: group_active_text,
      group_trial: group_trial_text,
    )

    mail(to: to_email)
  end
end
