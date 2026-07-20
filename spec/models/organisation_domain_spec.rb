require "rails_helper"

RSpec.describe OrganisationDomain do
  describe "validations" do
    it "has a valid factory" do
      expect(build(:organisation_domain)).to be_valid
    end

    it "is invalid without an organisation" do
      organisation_domain = described_class.new(domain: "example.gov.uk")
      expect(organisation_domain).not_to be_valid
    end

    it "is invalid without a domain" do
      organisation_domain = described_class.new(organisation: create(:organisation))
      expect(organisation_domain).not_to be_valid
    end

    it "is invalid when the domain already exists for the organisation" do
      organisation = create(:organisation)
      described_class.create!(organisation: organisation, domain: "example.gov.uk")
      duplicate_domain = described_class.new(organisation: organisation, domain: "example.gov.uk")
      expect(duplicate_domain).not_to be_valid
    end

    it_behaves_like "a domain validator" do
      let(:model) { described_class.new(organisation: create(:organisation)) }
      let(:attribute) { :domain }
    end
  end
end
