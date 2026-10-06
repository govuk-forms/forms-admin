require "rails_helper"

describe FeatureService do
  describe "#enabled?" do
    subject :feature_service do
      described_class.new(user:)
    end

    let(:organisation) { build :organisation, id: 1, slug: "a-test-org" }
    let(:user) { build :user, id: 1, organisation: }

    context "when the feature key has a boolean value" do
      context "when feature key has value true" do
        before do
          Settings.features[:some_feature] = true
        end

        it "is enabled" do
          expect(feature_service).to be_enabled(:some_feature)
        end
      end

      context "when feature key has value false" do
        before do
          Settings.features[:some_feature] = false
        end

        it "is not enabled" do
          expect(feature_service).not_to be_enabled(:some_feature)
        end
      end

      context "when empty features" do
        before do
          allow(Settings).to receive(:features).and_return(nil)
        end

        it "is not enabled" do
          expect(feature_service).not_to be_enabled(:some_feature)
        end
      end

      context "when nested features" do
        before do
          Settings.features[:some] = OpenStruct.new(nested_feature: true)
        end

        it "is enabled" do
          expect(feature_service).to be_enabled("some.nested_feature")
        end
      end
    end

    context "when the feature key has an object value" do
      context "when the enabled key exists and is set to true" do
        before do
          Settings.features[:some_feature] = Config::Options.new(enabled: true)
        end

        it "is enabled" do
          expect(feature_service).to be_enabled(:some_feature)
        end
      end

      context "when the enabled key exists and is set to false" do
        before do
          Settings.features[:some_feature] = Config::Options.new(enabled: false)
        end

        it "is not enabled" do
          expect(feature_service).not_to be_enabled(:some_feature)
        end
      end

      context "when the enabled key does not exist" do
        before do
          Settings.features[:some_feature] = Config::Options.new
        end

        it "is not enabled" do
          expect(feature_service).not_to be_enabled(:some_feature)
        end
      end

      context "when a key exists for the organisation overriding the feature to be enabled" do
        before do
          Settings.features[:some_feature] = Config::Options.new(enabled: false, organisations: { a_test_org: true })
        end

        it "is enabled" do
          expect(feature_service).to be_enabled(:some_feature)
        end
      end

      context "when a key exists for the organisation overriding the feature to be disabled" do
        before do
          Settings.features[:some_feature] = Config::Options.new(enabled: true, organisations: { a_test_org: false })
        end

        it "is not enabled" do
          expect(feature_service).not_to be_enabled(:some_feature)
        end
      end

      context "when a key exists for the organisation overriding the feature and the user has not been provided to the service" do
        let(:feature_service) { described_class.new }

        before do
          Settings.features[:some_feature] = Config::Options.new(enabled: false, organisations: { a_test_org: true })
        end

        it "raises an error" do
          expect { feature_service.enabled?(:some_feature) }.to raise_error described_class::UserRequiredError
        end
      end

      context "when a key exists for a different organisation" do
        before do
          Settings.features[:some_feature] = Config::Options.new(enabled: false, organisations: { 'another-org': true })
        end

        it "returns the value of the enabled flag" do
          expect(feature_service).not_to be_enabled(:some_feature)
        end
      end

      context "when the organisations object is empty" do
        before do
          Settings.features[:some_feature] = Config::Options.new(enabled: true, organisations: {})
        end

        it "returns the value of the enabled flag" do
          expect(feature_service).to be_enabled(:some_feature)
        end
      end

      context "when the user does not have an organisation set" do
        before do
          user.organisation = nil
          Settings.features[:some_feature] = Config::Options.new(enabled: false, organisations: { a_test_org: true })
        end

        it "returns the value of the enabled flag" do
          expect(feature_service).not_to be_enabled(:some_feature)
        end
      end

      context "when feature is enabled_by_group" do
        subject(:feature_service) { described_class.new(group:) }

        let(:group) { double }

        before do
          Settings.features[:test_feature] = Config::Options.new(enabled_by_group: true)
        end

        it "raises GroupRequiredError if group is not provided" do
          service = described_class.new

          expect {
            service.enabled?(:test_feature)
          }.to raise_error(
            described_class::GroupRequiredError,
            "Feature test_feature requires group to be provided",
          )
        end

        it "calls the corresponding enabled? method on the group" do
          allow(group).to receive(:test_feature_enabled?).and_return(true)

          expect(feature_service.enabled?(:test_feature)).to be true
        end

        it "returns false when group method returns false" do
          allow(group).to receive(:test_feature_enabled?).and_return(false)

          expect(feature_service.enabled?(:test_feature)).to be false
        end

        it "raises NoMethodError when group does not respond to the feature method" do
          allow(group).to receive(:method_missing).and_raise(NoMethodError)

          expect {
            feature_service.enabled?(:test_feature)
          }.to raise_error(NoMethodError)
        end
      end

      context "when feature is enabled_by_organisation" do
        subject(:feature_service) { described_class.new(organisation: flagged_organisation) }

        let(:flagged_organisation) { double }

        before do
          Settings.features[:test_feature] = Config::Options.new(enabled_by_organisation: true)
        end

        it "raises OrganisationRequiredError if organisation is not provided" do
          service = described_class.new

          expect {
            service.enabled?(:test_feature)
          }.to raise_error(
            described_class::OrganisationRequiredError,
            "Feature test_feature requires organisation to be provided",
          )
        end

        it "calls the corresponding enabled? method on the organisation" do
          allow(flagged_organisation).to receive(:test_feature_enabled?).and_return(true)

          expect(feature_service.enabled?(:test_feature)).to be true
        end

        it "returns false when organisation method returns false" do
          allow(flagged_organisation).to receive(:test_feature_enabled?).and_return(false)

          expect(feature_service.enabled?(:test_feature)).to be false
        end
      end
    end
  end

  describe ".enabled" do
    context "when the feature key has a boolean value" do
      before do
        Settings.features[:some_feature] = true
      end

      it "resolves the boolean value of a feature" do
        expect(described_class).to be_enabled(:some_feature)
      end
    end

    context "when the feature key has an object value" do
      before do
        Settings.features[:some_feature] = Config::Options.new(enabled: true)
      end

      it "resolves the value of the enabled flag" do
        expect(described_class).to be_enabled(:some_feature)
      end
    end
  end
end
