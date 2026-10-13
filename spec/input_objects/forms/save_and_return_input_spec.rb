require "rails_helper"

RSpec.describe Forms::SaveAndReturnInput, type: :model do
  let(:form) { create(:form, save_and_return:) }
  let(:save_and_return) { "disabled" }

  describe "validation" do
    it "is valid when save_and_return is 'enabled'" do
      expect(described_class.new(form:, save_and_return: "enabled")).to be_valid
    end

    it "is valid when save_and_return is 'disabled'" do
      expect(described_class.new(form:, save_and_return: "disabled")).to be_valid
    end

    it "is invalid when save_and_return is not allowed value" do
      expect(described_class.new(form:, save_and_return: "invalid")).not_to be_valid
    end

    it "is invalid when save_and_return is nil" do
      expect(described_class.new(form: form, save_and_return: nil)).not_to be_valid
    end
  end

  describe "#submit" do
    subject(:input) { described_class.new(form:, save_and_return: value) }

    context "when enabling" do
      let(:save_and_return) { "disabled" }
      let(:value) { "enabled" }

      it "updates the form save_and_return flag to 'enabled'" do
        expect { input.submit }.to change { form.reload.save_and_return }.to(value)
      end
    end

    context "when disabling" do
      let(:save_and_return) { "enabled" }
      let(:value) { "disabled" }

      it "updates the form save_and_return flag to 'disabled'" do
        expect { input.submit }.to change { form.reload.save_and_return }.to(value)
      end
    end

    context "when save_and_return is invalid" do
      let(:value) { "invalid" }

      it "returns false and does not update the form" do
        expect(input.submit).to be false
        expect(form.reload.save_and_return).to eq("disabled")
      end
    end
  end

  describe "#assign_form_values" do
    subject(:input) { described_class.new(form:) }

    let(:save_and_return) { "enabled" }

    it "sets the save_and_return value from the form" do
      input.assign_form_values

      expect(input.save_and_return).to eq("enabled")
    end
  end
end
