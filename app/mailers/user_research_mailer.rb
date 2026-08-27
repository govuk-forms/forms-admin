class UserResearchMailer < GovukNotifyRails::Mailer
  def invitation_email(user)
    set_template(Settings.govuk_notify.user_research_invitation_template_id)
    set_email_reply_to(Settings.govuk_notify.zendesk_reply_to_id)

    set_personalisation(name: user.name)

    mail(to: user.email)
  end
end
