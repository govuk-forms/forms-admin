class Account::ConfirmOrganisationInput < BaseInput
  attr_accessor :organisation, :confirm

  RADIO_OPTIONS = { yes: "yes", no: "no" }.freeze

  validate :validate_confirm

  def confirmed?
    confirm == RADIO_OPTIONS[:yes]
  end

  def values
    RADIO_OPTIONS.keys
  end

private

  def validate_confirm
    if confirm.blank? || !RADIO_OPTIONS.values.include?(confirm)
      errors.add(:confirm, :blank, organisation: organisation.name_with_abbreviation)
    end
  end
end
