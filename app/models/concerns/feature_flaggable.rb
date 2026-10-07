module FeatureFlaggable
  extend ActiveSupport::Concern

  class_methods do
    # Feature flag columns that super admins can toggle per record. Derived from the
    # features in settings.yml marked `enabled_by_<model>: true` (for example
    # `enabled_by_group` for Group) that also have a matching `*_enabled` column.
    # Features without a column, e.g. exit_pages, are skipped.
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
