class Brand < ApplicationRecord
  has_many :organisation_brands, dependent: :destroy

  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, allow_blank: true }
  validates :name, presence: true
end
