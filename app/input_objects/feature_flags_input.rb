module Organisations
  class FeatureFlagsInput < BaseInput
    attr_accessor :organisation

    def initialize(attributes = {})
      # The flag attributes depend on the app settings and the organisations schema,
      # so they cannot be defined when the class is loaded.
      Organisation.feature_flag_attributes.each do |flag|
        singleton_class.attr_accessor(flag)
      end

      super
    end

    def assign_organisation_values
      Organisation.feature_flag_attributes.each do |flag|
        public_send(:"#{flag}=", organisation[flag])
      end
      self
    end

    def submit
      return false if invalid?

      # Feature flags can only be switched on, never off. Enabling a feature can change
      # an organisation's groups or forms in ways that would need to be manually reversed
      # before it is safe to disable, so we only ever turn flags on here.
      organisation.assign_attributes(flags_to_enable.index_with(true))
      @flags_changed = organisation.changed?

      return true if organisation.save

      errors.merge!(organisation.errors)
      organisation.restore_attributes(flags_to_enable)
      false
    end

    def flags_changed?
      @flags_changed
    end

    # A flag that is saved as on cannot be turned off, so its checkbox is locked.
    def flag_locked?(flag)
      organisation.attribute_in_database(flag) == true
    end

    def flag_checked?(flag)
      flag_locked?(flag) || flag_ticked?(flag)
    end

  private

    def flags_to_enable
      Organisation.feature_flag_attributes.select { |flag| flag_ticked?(flag) }
    end

    def flag_ticked?(flag)
      ActiveModel::Type::Boolean.new.cast(public_send(flag)) == true
    end
  end
end
