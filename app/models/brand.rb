class Brand < ApplicationRecord
  has_many :organisation_brands, dependent: :destroy

  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, allow_blank: true }
  validates :name, presence: true
  validates :header_background_colour, :border_colour, presence: true, format: { with: /\A#[0-9a-f]{6}\z/, allow_blank: true }
  validates :logo_link, presence: true, format: { with: %r{\Ahttps?://.*\z}, allow_blank: true }
  validates :logo_alt_text, :copyright_holder, presence: true
end
