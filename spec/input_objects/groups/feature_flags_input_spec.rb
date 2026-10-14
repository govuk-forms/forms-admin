require "rails_helper"

RSpec.describe Groups::FeatureFlagsInput, type: :model do
  let(:feature_flag) { Group.feature_flag_attributes.first }
  let(:record) { create :group, feature_flag => false }
  let(:record_name) { :group }

  before do
    skip "no group feature flags are configured" if Group.feature_flag_attributes.empty?
  end

  it_behaves_like "a feature flags input"
end
