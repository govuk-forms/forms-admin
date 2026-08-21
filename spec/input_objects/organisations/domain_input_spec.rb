require "rails_helper"

describe Organisations::DomainInput do
  subject(:domain_input) { described_class.new }

  let(:organisation) { create(:organisation) }

  describe "validations" do
    it "is valid with an organisation and a domain" do
      domain_input.organisation = organisation
      domain_input.domain = "example.com"
      expect(domain_input).to be_valid
    end

    it "is invalid without an organisation" do
      domain_input.domain = "example.com"
      expect(domain_input).not_to be_valid
      expect(domain_input.errors[:organisation]).to include("can't be blank")
    end

    it "is invalid without a domain" do
      domain_input.organisation = organisation
      expect(domain_input).not_to be_valid
      expect(domain_input.errors[:domain]).to include("can't be blank")
    end
  end

  describe "#submit" do
    context "when the input is invalid" do
      it "returns false and does not create an OrganisationDomain" do
        expect(domain_input.submit).to be false
        expect(OrganisationDomain.count).to eq 0
      end
    end

    context "when the input is valid" do
      before do
        domain_input.organisation = organisation
        domain_input.domain = "example.com"
      end

      it "creates a new OrganisationDomain for the organisation" do
        expect { domain_input.submit }.to change(OrganisationDomain, :count).by(1)

        organisation_domain = OrganisationDomain.last
        expect(organisation_domain.organisation).to eq organisation
        expect(organisation_domain.domain).to eq "example.com"
      end

      it "returns the created OrganisationDomain" do
        expect(domain_input.submit).to be_a OrganisationDomain
      end
    end

    context "when the domain is already associated with the organisation" do
      before do
        create(:organisation_domain, organisation:, domain: "example.com")
        domain_input.organisation = organisation
        domain_input.domain = "example.com"
      end

      it "raises an ActiveRecord::RecordInvalid error" do
        expect { domain_input.submit }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when the domain is not a valid format" do
      before do
        domain_input.organisation = organisation
        domain_input.domain = "not a domain"
      end

      it "raises an ActiveRecord::RecordInvalid error" do
        expect { domain_input.submit }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
