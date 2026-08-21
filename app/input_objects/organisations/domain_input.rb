module Organisations
  class DomainInput < BaseInput
    attr_accessor :organisation, :domain

    validates :organisation, presence: true
    validates :domain, presence: true, domain: true

    def submit
      return false if invalid?

      organisation.organisation_domains.create!(domain:)
    end
  end
end
