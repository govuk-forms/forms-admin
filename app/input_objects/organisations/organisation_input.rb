module Organisations
  class OrganisationInput < BaseInput
    attr_accessor :name
    attr_reader :created_organisation

    validates :name, presence: true
    validate :name_is_unique, if: -> { name.present? }

    def submit
      return false if invalid?

      @created_organisation = Organisation.create!(name:, slug: name.parameterize)
    end

  private

    def name_is_unique
      errors.add(:name, :taken) if Organisation.exists?(name: name) || Organisation.exists?(slug: name.parameterize)
    end
  end
end
