class OrganisationDomain < ApplicationRecord
  belongs_to :organisation

  validates :domain, presence: true
  validates :domain, uniqueness: { scope: :organisation_id, case_sensitive: false }
  validates :domain, domain: true

  before_validation -> { self.domain = domain&.downcase&.strip }
end
