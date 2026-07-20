class OrganisationBrand < ApplicationRecord
  belongs_to :organisation
  belongs_to :brand

  validates :brand_id, uniqueness: { scope: :organisation_id }
end
