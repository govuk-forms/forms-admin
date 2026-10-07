require "rails_helper"

describe Organisations::OrganisationInput do
  subject(:organisation_input) { described_class.new }

  describe "validations" do
    it "is valid with a name and a domain" do
      organisation_input.name = "Department for Testing"
      organisation_input.domain = "example.gov.uk"
      expect(organisation_input).to be_valid
    end

    it "is invalid without a name" do
      organisation_input.domain = "example.gov.uk"
      expect(organisation_input).not_to be_valid
      expect(organisation_input.errors[:name]).to include("Enter an organisation name")
    end

    it "is invalid without a domain" do
      organisation_input.name = "Department for Testing"
      expect(organisation_input).not_to be_valid
      expect(organisation_input.errors[:domain]).to include("Enter a domain name")
    end

    it "is invalid with a badly formatted domain" do
      organisation_input.name = "Department for Testing"
      organisation_input.domain = "not a domain"
      expect(organisation_input).not_to be_valid
      expect(organisation_input.errors[:domain]).to include("Enter a domain name in the correct format, like subdomain.gov.uk")
    end

    it "is invalid when an organisation with the same name already exists" do
      create(:organisation, name: "Department for Testing", slug: "different-slug")
      organisation_input.name = "Department for Testing"

      expect(organisation_input).not_to be_valid
      expect(organisation_input.errors[:name]).to include("An organisation with this name already exists")
    end

    it "is invalid when an organisation with the same slug already exists" do
      create(:organisation, name: "Department for Testing", slug: "department-for-testing")
      organisation_input.name = "Department for Testing"

      expect(organisation_input).not_to be_valid
      expect(organisation_input.errors[:name]).to include("An organisation with this name already exists")
    end
  end

  describe "#submit" do
    context "when the input is invalid" do
      it "returns false and does not create an Organisation" do
        expect(organisation_input.submit).to be false
        expect(Organisation.count).to eq 0
      end
    end

    context "when the input is valid" do
      before do
        organisation_input.name = "Department for Testing"
        organisation_input.domain = "example.gov.uk"
      end

      it "creates a new Organisation with the correct name and slug" do
        expect { organisation_input.submit }.to change(Organisation, :count).by(1)

        organisation = Organisation.last
        expect(organisation.name).to eq "Department for Testing"
        expect(organisation.slug).to eq "department-for-testing"
      end

      it "creates an OrganisationDomain for the new organisation" do
        expect { organisation_input.submit }.to change(OrganisationDomain, :count).by(1)

        expect(OrganisationDomain.last.domain).to eq "example.gov.uk"
        expect(OrganisationDomain.last.organisation).to eq Organisation.last
      end

      it "exposes the created organisation via #created_organisation" do
        organisation_input.submit
        expect(organisation_input.created_organisation).to eq Organisation.last
      end
    end
  end
end
