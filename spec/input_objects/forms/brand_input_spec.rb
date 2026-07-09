require "rails_helper"

RSpec.describe Forms::BrandInput, type: :model do
  let(:form) do
    create(:form, :live)
  end

  let!(:brand) { create(:brand, slug: "cheshire-east", name: "Cheshire East Council") }
  let!(:other_brand) { create(:brand, slug: "south-gloucestershire", name: "South Gloucestershire Council") }

  describe "validations" do
    context "when given a blank brand_id" do
      it "validates successfully" do
        brand_input = described_class.new(form:, brand_id: "")

        expect(brand_input).to be_valid
      end
    end

    context "when given a brand_id from the configured list" do
      it "validates successfully" do
        brand_input = described_class.new(form:, brand_id: brand.slug)

        expect(brand_input).to be_valid
      end
    end

    context "when given a brand_id that is not in the configured list" do
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
    it "starts with the GOV.UK default option followed by the configured brands ordered by name" do
      brand_input = described_class.new(form:)

      expect(brand_input.brand_options.first).to have_attributes(id: "", name: "GOV.UK (default)")
      expect(brand_input.brand_options.drop(1).map(&:id)).to eq([brand.slug, other_brand.slug])
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
