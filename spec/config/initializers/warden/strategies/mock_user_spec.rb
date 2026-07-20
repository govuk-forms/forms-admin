require "rails_helper"

RSpec.describe Warden::Strategies[:mock_user] do
  subject(:strategy) { described_class.new({}) }

  describe "#valid?" do
    it { is_expected.to be_valid }
  end

  describe "#authenticate!" do
    context "when a user exists in the database" do
      let!(:user) { create :user }

      before do
        strategy.authenticate!
      end

      it { is_expected.to be_successful }

      it "signs in as the first user in the database" do
        expect(strategy.user).to eq user
      end
    end

    context "when no user exists in the database" do
      before do
        strategy.authenticate!
      end

      it { is_expected.not_to be_successful }
    end
  end
end
