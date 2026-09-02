class Account::OrganisationInput < BaseInput
  attr_accessor :user, :allowed_organisations, :organisation_id

  validates :organisation_id, presence: true, inclusion: { in: ->(record) { record.allowed_organisation_ids } }

  NOT_LISTED_OPTION_VALUE = "not_listed".freeze

  def submit
    return false if invalid?

    user.organisation_id = organisation_id

    if user.save!
      log_organisation_chosen_event
      true
    end
  end

  def assign_form_values
    self.organisation_id = user.organisation_id
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
