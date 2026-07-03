class Account::OrganisationInput < BaseInput
  attr_accessor :user, :allowed_organisations, :organisation_id

  validates :organisation_id, presence: true, inclusion: { in: ->(record) { record.allowed_organisations.pluck(:id).map(&:to_s) } }

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

private

  def log_organisation_chosen_event
    Rails.logger.info("User chose their organisation", {
      organisation_id:,
    })
  end
end
