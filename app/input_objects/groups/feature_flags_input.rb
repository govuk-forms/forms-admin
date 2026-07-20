module Groups
  class FeatureFlagsInput < BaseInput
    attr_accessor :group

    def initialize(attributes = {})
      # The flag attributes depend on the app settings and the groups schema, so
      # they cannot be defined when the class is loaded.
      Group.feature_flag_attributes.each do |flag|
        singleton_class.attr_accessor(flag)
      end

      super
    end

    def assign_group_values
      Group.feature_flag_attributes.each do |flag|
        public_send(:"#{flag}=", group[flag])
      end
      self
    end

    def submit
      return false if invalid?

      # Feature flags can only be switched on, never off. Enabling a feature can change
      # a group's forms or data in ways that would need to be manually reversed before
      # it is safe to disable, so we only ever turn flags on here.
      group.assign_attributes(flags_to_enable.index_with(true))
      @flags_changed = group.changed?

      return true if group.save

      errors.merge!(group.errors)
      false
    end

    def flags_changed?
      @flags_changed
    end

  private

    def flags_to_enable
      Group.feature_flag_attributes.select do |flag|
        ActiveModel::Type::Boolean.new.cast(public_send(flag))
      end
    end
  end
end
