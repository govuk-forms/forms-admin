class Account::ContactForResearchInput < BaseInput
  attr_accessor :user, :research_contact_status

  RADIO_OPTIONS = %w[consented declined].freeze

  validates :research_contact_status, presence: true, inclusion: { in: RADIO_OPTIONS }

  def submit
    return false if invalid?

    user.research_contact_status = research_contact_status
    user.user_research_opted_in_at = Time.zone.now
    user.save!

    send_invitation_email if user.research_contact_status_previously_changed?(to: "consented")

    true
  end

  def values
    RADIO_OPTIONS
  end

private

  def send_invitation_email
    UserResearchMailer.invitation_email(user).deliver_now
  rescue StandardError => e
    Sentry.capture_exception(e)
  end
end
