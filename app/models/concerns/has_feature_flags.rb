module HasFeatureFlags
  extend ActiveSupport::Concern

  class_methods do
    # Feature flag columns that super admins can toggle per record. Derived from
    # the features in settings.yml marked with this model's setting (for example
    # `enabled_by_group: true` for groups) that also have a matching `*_enabled` column.
    def feature_flag_attributes
      return [] if Settings.features.blank?

      setting = :"enabled_by_#{model_name.singular}"

      Settings.features.filter_map do |name, config|
        column = "#{name}_enabled"
        column if config.respond_to?(setting) && config.public_send(setting) && has_attribute?(column)
      end
    end
  end
end
