module Organisations
  class BrandInput < BaseInput
    attr_accessor :organisation, :brand_id

    validates :brand_id, presence: true
    validate :brand_is_available, if: -> { brand_id.present? }

    def submit
      return false if invalid?

      organisation.organisation_brands.create!(brand:)
      true
    end

    def brand
      @brand ||= Brand.find_by(id: brand_id)
    end

    def available_brands
      Brand.where.not(id: organisation.brands.select(:id)).order(:name)
    end

  private

    def brand_is_available
      errors.add(:brand_id, :inclusion) unless available_brands.exists?(id: brand_id)
    end
  end
end
