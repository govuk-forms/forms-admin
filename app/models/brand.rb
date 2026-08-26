class Brand < ApplicationRecord
  ASSET_CONTENT_TYPES = {
    logo: %w[image/png image/jpeg],
    favicon: %w[image/vnd.microsoft.icon image/x-icon image/png],
    opengraph_image: %w[image/png image/jpeg],
  }.freeze

  has_many :organisation_brands, dependent: :destroy

  has_one_attached :logo
  has_one_attached :favicon
  has_one_attached :opengraph_image

  attr_accessor :logo_file, :favicon_file, :opengraph_image_file

  before_validation :set_slug, on: :create

  validates :slug, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, allow_blank: true }
  validates :name, presence: true
  validate :name_must_generate_available_slug, on: :create
  validates :header_background_colour, :border_colour, presence: true, format: { with: /\A#[0-9a-f]{6}\z/, allow_blank: true }
  validates :logo_link, presence: true, format: { with: %r{\Ahttps?://.*\z}, allow_blank: true }
  validates :logo_alt_text, :copyright_holder, presence: true
  validates :logo_file, file_content_type: { in: ASSET_CONTENT_TYPES[:logo] }
  validates :favicon_file, file_content_type: { in: ASSET_CONTENT_TYPES[:favicon] }
  validates :opengraph_image_file, file_content_type: { in: ASSET_CONTENT_TYPES[:opengraph_image] }

  def logo_path
    asset_path(logo)
  end

  def favicon_path
    asset_path(favicon)
  end

  def opengraph_image_path
    asset_path(opengraph_image)
  end

private

  def set_slug
    self.slug = name.parameterize if slug.blank? && name.present?
  end

  # the slug is derived from the name, so errors are added to name rather
  # than slug, which has no field in the new brand form
  def name_must_generate_available_slug
    return if name.blank?

    if slug.blank?
      errors.add(:name, :no_letters_or_numbers)
    elsif Brand.exists?(slug:)
      errors.add(:name, :taken)
    end
  end

  # blob keys are paths under /assets/, which CloudFront serves from the
  # assets bucket
  def asset_path(attachment)
    "/#{attachment.blob.key}" if attachment.attached?
  end
end
