class Account::OrganisationInput < BaseInput
  attr_accessor :pending_user, :allowed_organisations, :organisation_id

  validates :organisation_id, presence: true, inclusion: { in: ->(record) { record.allowed_organisation_ids } }

  NOT_LISTED_OPTION_VALUE = "not_listed".freeze

  def submit
    return false if invalid?

    pending_user.organisation_id = organisation_id

    pending_user.save!
    log_organisation_chosen_event
    true
  end

  def assign_form_values
    self.organisation_id = pending_user.organisation_id
    self
  end

  def radios?
    allowed_organisations.size <= 30
  end

  def not_listed_selected?
    organisation_id == NOT_LISTED_OPTION_VALUE
  end

  def allowed_organisation_ids
    allowed_organisations.pluck(:id).map(&:to_s)
  end

private

  def log_organisation_chosen_event
    Rails.logger.info("User chose their organisation", {
      organisation_id:,
    })
  end
end
