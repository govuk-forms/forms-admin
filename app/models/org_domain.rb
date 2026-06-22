# frozen_string_literal: true

class OrgDomain < ApplicationRecord
  belongs_to :organisation

  validates :domain, presence: true
  validates :domain, uniqueness: { scope: :organisation_id, case_sensitive: false }

  before_validation -> { self.domain = domain&.downcase&.strip }
end
