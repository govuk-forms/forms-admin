# frozen_string_literal: true

require "rails_helper"

describe "Settings" do
  settings = YAML.load_file(Rails.root.join("config/settings.yml")).with_indifferent_access
  expected_value_test = "expected_value_test"
  has_a_default_value = "has a default value"

  shared_examples expected_value_test do |key, source, expected_value|
    describe ".#{key}" do
      subject do
        source[key]
      end

      it "#{key} has a default value" do
        expect(subject).to eq(expected_value)
      end
    end
  end

  describe ".features" do
    features = settings[:features]

    include_examples expected_value_test, :show_relevant_organisations, features, false

    describe "group-scoped feature flags" do
      group_features = features.select { |_, config| config.is_a?(Hash) && config["enabled_by_group"] }

      it "has a settings entry for every feature flag column on the groups table" do
        feature_flag_columns = Group.column_names.grep(/_enabled\z/)
        settings_feature_columns = group_features.keys.map { |name| "#{name}_enabled" }

        expect(settings_feature_columns).to include(*feature_flag_columns)
      end

      it "has a label for every feature flag on the feature flags page" do
        Group.feature_flag_attributes.each do |attribute|
          translation_key = "groups.feature_flags.flags.#{attribute}"
          expect(I18n.exists?(translation_key)).to be(true), "expected a translation for #{translation_key}"
        end
      end
    end
  end

  describe "forms_api" do
    forms_api = settings[:forms_api]

    include_examples expected_value_test, :auth_key, forms_api, "development_key"

    include_examples expected_value_test, :base_url, forms_api, "http://localhost:9292"
  end

  describe "govuk_notify" do
    govuk_notify = settings[:govuk_notify]

    include_examples expected_value_test, :api_key, govuk_notify, "changeme"

    include_examples expected_value_test, :submission_email_confirmation_code_email_template_id, govuk_notify, "ce2638ab-754c-416d-8df6-c0ccb5e1a688"
  end

  describe "sentry" do
    sentry = settings[:sentry]

    include_examples expected_value_test, :dsn, sentry, nil

    include_examples expected_value_test, :environment, sentry, "local"
  end

  describe "maintenance_mode" do
    maintenance_mode = settings[:maintenance_mode]

    include_examples expected_value_test, :enabled, maintenance_mode, false

    include_examples expected_value_test, :bypass_ips, maintenance_mode, nil
  end

  describe "forms_env" do
    it has_a_default_value do
      forms_env = settings[:forms_env]

      expect(forms_env).to eq("local")
    end
  end

  describe "analytics_enabled" do
    it has_a_default_value do
      analytics_enabled = settings[:analytics_enabled]

      expect(analytics_enabled).to be(false)
    end
  end

  describe "act_as_user_enabled" do
    it has_a_default_value do
      act_as_user_enabled = settings[:act_as_user_enabled]

      expect(act_as_user_enabled).to be(false)
    end
  end
end
