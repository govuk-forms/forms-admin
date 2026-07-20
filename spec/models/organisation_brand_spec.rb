require "rails_helper"

RSpec.describe OrganisationBrand do
  describe "validations" do
    it "has a valid factory" do
      expect(build(:organisation_brand)).to be_valid
    end

    it "is invalid without an organisation" do
      organisation_brand = described_class.new(brand: create(:brand))
      expect(organisation_brand).not_to be_valid
    end

    it "is invalid without a brand" do
      organisation_brand = described_class.new(organisation: create(:organisation))
      expect(organisation_brand).not_to be_valid
    end

    it "is invalid when the brand is already added to the organisation" do
      organisation_brand = create(:organisation_brand)
      duplicate = described_class.new(organisation: organisation_brand.organisation, brand: organisation_brand.brand)
      expect(duplicate).not_to be_valid
    end

    it "is valid when the brand is added to a different organisation" do
      organisation_brand = create(:organisation_brand)
      other_organisation = create(:organisation, slug: "other-org")
      other_organisation_brand = build(:organisation_brand, organisation: other_organisation, brand: organisation_brand.brand)
      expect(other_organisation_brand).to be_valid
    end
  end
end
