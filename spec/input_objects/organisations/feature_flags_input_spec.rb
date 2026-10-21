require "rails_helper"

RSpec.describe Organisations::FeatureFlagsInput, type: :model do
  # No feature is organisation-scoped yet, so use an existing boolean column as a stand-in flag
  let(:feature_flag) { "internal" }
  let(:record) { create :organisation, feature_flag => false }
  let(:record_name) { :organisation }

  before do
    allow(Organisation).to receive(:feature_flag_attributes).and_return([feature_flag])
  end

  it_behaves_like "a feature flags input"
end
