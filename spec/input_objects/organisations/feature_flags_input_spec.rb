require "rails_helper"

RSpec.describe Organisations::FeatureFlagsInput, type: :model do
  # No feature is organisation-scoped yet, so use an existing boolean column as a stand-in flag
  let(:feature_flag) { "internal" }
  let(:organisation) { create :organisation, feature_flag => false }

  before do
    allow(Organisation).to receive(:feature_flag_attributes).and_return([feature_flag])
  end

  describe "#assign_organisation_values" do
    it "copies the organisation's flag values onto the input" do
      organisation.update!(feature_flag => true)

      input = described_class.new(organisation:).assign_organisation_values

      expect(input.public_send(feature_flag)).to be(true)
    end
  end

  describe "#submit" do
    it "enables a flag submitted as true" do
      input = described_class.new({ organisation:, feature_flag => "true" })

      expect(input.submit).to be(true)
      expect(organisation.reload[feature_flag]).to be(true)
    end

    it "does not turn a flag off when submitted as false" do
      organisation.update!(feature_flag => true)

      input = described_class.new({ organisation:, feature_flag => "false" })

      expect(input.submit).to be(true)
      expect(organisation.reload[feature_flag]).to be(true)
    end

    context "when the organisation cannot be saved" do
      let(:input) { described_class.new({ organisation:, feature_flag => "true" }) }

      before do
        allow(organisation).to receive(:save).and_return(false)
      end

      it "returns false and leaves the organisation's flag unchanged" do
        expect(input.submit).to be(false)
        expect(organisation[feature_flag]).to be(false)
      end

      it "keeps the submitted flag checked but not locked" do
        input.submit

        expect(input.flag_checked?(feature_flag)).to be(true)
        expect(input.flag_locked?(feature_flag)).to be(false)
      end
    end
  end

  describe "#flag_locked?" do
    it "is true when the flag is saved as on" do
      organisation.update!(feature_flag => true)

      expect(described_class.new(organisation:).flag_locked?(feature_flag)).to be(true)
    end

    it "is false when the flag has only been turned on in memory" do
      organisation.assign_attributes(feature_flag => true)

      expect(described_class.new(organisation:).flag_locked?(feature_flag)).to be(false)
    end
  end

  describe "#flag_checked?" do
    it "is true when the flag is saved as on, even if submitted as false" do
      organisation.update!(feature_flag => true)

      input = described_class.new({ organisation:, feature_flag => "false" })

      expect(input.flag_checked?(feature_flag)).to be(true)
    end

    it "is true when the flag is submitted as true" do
      input = described_class.new({ organisation:, feature_flag => "true" })

      expect(input.flag_checked?(feature_flag)).to be(true)
    end

    it "is false when the flag is off and not submitted" do
      expect(described_class.new(organisation:).flag_checked?(feature_flag)).to be(false)
    end
  end

  describe "#flags_changed?" do
    it "is true when submitting enabled a flag" do
      input = described_class.new({ organisation:, feature_flag => "true" })
      input.submit

      expect(input.flags_changed?).to be(true)
    end

    it "is false when submitting made no changes" do
      organisation.update!(feature_flag => true)

      input = described_class.new({ organisation:, feature_flag => "true" })
      input.submit

      expect(input.flags_changed?).to be(false)
    end
  end
end
