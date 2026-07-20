require "rails_helper"

RSpec.describe Groups::FeatureFlagsInput, type: :model do
  let(:feature_flag) { Group.feature_flag_attributes.first }
  let(:group) { create :group, feature_flag => false }

  before do
    skip "no group feature flags are configured" if Group.feature_flag_attributes.empty?
  end

  describe "#assign_group_values" do
    it "copies the group's flag values onto the input" do
      group.update!(feature_flag => true)

      input = described_class.new(group:).assign_group_values

      expect(input.public_send(feature_flag)).to be(true)
    end
  end

  describe "#submit" do
    it "enables a flag submitted as true" do
      input = described_class.new({ group:, feature_flag => "true" })

      expect(input.submit).to be(true)
      expect(group.reload[feature_flag]).to be(true)
    end

    it "does not turn a flag off when submitted as false" do
      group.update!(feature_flag => true)

      input = described_class.new({ group:, feature_flag => "false" })

      expect(input.submit).to be(true)
      expect(group.reload[feature_flag]).to be(true)
    end
  end

  describe "#flags_changed?" do
    it "is true when submitting enabled a flag" do
      input = described_class.new({ group:, feature_flag => "true" })
      input.submit

      expect(input.flags_changed?).to be(true)
    end

    it "is false when submitting made no changes" do
      group.update!(feature_flag => true)

      input = described_class.new({ group:, feature_flag => "true" })
      input.submit

      expect(input.flags_changed?).to be(false)
    end
  end
end
