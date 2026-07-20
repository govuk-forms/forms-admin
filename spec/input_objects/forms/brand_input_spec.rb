require "rails_helper"

RSpec.describe Forms::BrandInput, type: :model do
  let(:organisation) { create(:organisation) }
  let(:group) { create(:group, organisation:) }
  let(:form) do
    create(:form, :live, :with_group, group:)
  end

  let(:cheshire_east) { create(:brand, slug: "cheshire-east", name: "Cheshire East Council") }
  let(:south_gloucestershire) { create(:brand, slug: "south-gloucestershire", name: "South Gloucestershire Council") }

  before do
    create(:organisation_brand, organisation:, brand: cheshire_east)
    create(:organisation_brand, organisation:, brand: south_gloucestershire)
  end

  describe "validations" do
    context "when given a blank brand_id" do
      it "validates successfully" do
        brand_input = described_class.new(form:, brand_id: "")

        expect(brand_input).to be_valid
      end
    end

    context "when given a brand_id from the organisation's brands" do
      it "validates successfully" do
        brand_input = described_class.new(form:, brand_id: "cheshire-east")

        expect(brand_input).to be_valid
      end
    end

    context "when given a brand_id that is not one of the organisation's brands" do
      it "returns a validation error" do
        create(:brand, slug: "not-allowed-for-organisation")

        brand_input = described_class.new(form:, brand_id: "not-allowed-for-organisation")

        brand_input.validate(:brand_id)

        expect(brand_input.errors.full_messages_for(:brand_id)).to include(
          "Brand Select a brand",
        )
      end
    end

    context "when given a brand_id that does not exist" do
      it "returns a validation error" do
        brand_input = described_class.new(form:, brand_id: "not-a-brand")

        brand_input.validate(:brand_id)

        expect(brand_input.errors.full_messages_for(:brand_id)).to include(
          "Brand Select a brand",
        )
      end
    end
  end

  describe "#brand_options" do
    it "starts with the GOV.UK default option followed by the organisation's brands" do
      brand_input = described_class.new(form:)

      expect(brand_input.brand_options.first).to have_attributes(id: "", name: "GOV.UK (default)")
      expect(brand_input.brand_options.drop(1).map(&:id)).to eq %w[cheshire-east south-gloucestershire]
    end

    context "when the organisation has no brands" do
      let(:other_organisation) { create(:organisation, slug: "other-org") }
      let(:group) { create(:group, organisation: other_organisation) }

      it "only includes the GOV.UK default option" do
        brand_input = described_class.new(form:)

        expect(brand_input.brand_options.map(&:id)).to eq [""]
      end
    end

    context "when the form is not in a group" do
      let(:form) { create(:form, :live) }

      it "only includes the GOV.UK default option" do
        brand_input = described_class.new(form:)

        expect(brand_input.brand_options.map(&:id)).to eq [""]
      end
    end
  end

  describe "#submit" do
    context "when given a brand_id" do
      it "saves the brand_id to the form" do
        brand_input = described_class.new(form:, brand_id: "cheshire-east")

        expect(brand_input.submit).to be true
        expect(form.reload.brand_id).to eq "cheshire-east"
      end
    end

    context "when given a blank brand_id" do
      it "clears the brand_id on the form" do
        form.update!(brand_id: "cheshire-east")
        brand_input = described_class.new(form:, brand_id: "")

        expect(brand_input.submit).to be true
        expect(form.reload.brand_id).to be_nil
      end
    end

    context "when the input is invalid" do
      it "does not save and returns false" do
        brand_input = described_class.new(form:, brand_id: "not-a-brand")

        expect(brand_input.submit).to be false
        expect(form.reload.brand_id).to be_nil
      end
    end
  end

  describe "#assign_form_values" do
    context "when the form has a brand" do
      it "assigns the form's brand_id" do
        form.update!(brand_id: "cheshire-east")
        brand_input = described_class.new(form:).assign_form_values

        expect(brand_input.brand_id).to eq "cheshire-east"
      end
    end

    context "when the form has no brand" do
      it "assigns an empty string so the default option is preselected" do
        brand_input = described_class.new(form:).assign_form_values

        expect(brand_input.brand_id).to eq ""
      end
    end
  end
end
