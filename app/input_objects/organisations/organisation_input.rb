module Organisations
  class OrganisationInput < BaseInput
    attr_accessor :name, :domain
    attr_reader :created_organisation

    validates :name, presence: true
    validates :domain, presence: true, domain: true
    validate :name_is_unique, if: -> { name.present? }

    def submit
      return false if invalid?

      ActiveRecord::Base.transaction do
        @created_organisation = Organisation.create!(name:, slug: name.parameterize)
        @created_organisation.organisation_domains.create!(domain:)
      end
    end

  private

    def name_is_unique
      errors.add(:name, :taken) if Organisation.exists?(name: name) || Organisation.exists?(slug: name.parameterize)
    end
  end
end
