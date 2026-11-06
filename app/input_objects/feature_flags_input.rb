# Base class for the inputs super admins use to turn on a record's feature flags.
# Subclasses define the record attribute and the class whose flags they manage.
class FeatureFlagsInput < BaseInput
  class << self
    attr_reader :record_class

    def feature_flags_for(record_name, record_class)
      attr_accessor record_name

      alias_method :record, record_name
      @record_class = record_class
    end
  end

  def initialize(attributes = {})
    # The flag attributes depend on the app settings and the database schema, so
    # they cannot be defined when the class is loaded.
    feature_flag_attributes.each do |flag|
      singleton_class.attr_accessor(flag)
    end

    super
  end

  def assign_values
    feature_flag_attributes.each do |flag|
      public_send(:"#{flag}=", record[flag])
    end
    self
  end

  def submit
    return false if invalid?

    # Feature flags can only be switched on, never off. Enabling a feature can change
    # a record's forms or data in ways that would need to be manually reversed before
    # it is safe to disable, so we only ever turn flags on here.
    record.assign_attributes(flags_to_enable.index_with(true))
    @flags_changed = record.changed?

    return true if record.save

    errors.merge!(record.errors)
    record.restore_attributes(flags_to_enable)
    false
  end

  def flags_changed?
    @flags_changed
  end

  # A flag that is saved as on cannot be turned off, so its checkbox is locked.
  def flag_locked?(flag)
    record.attribute_in_database(flag) == true
  end

  def flag_checked?(flag)
    flag_locked?(flag) || flag_ticked?(flag)
  end

  def feature_flag_attributes
    self.class.record_class.feature_flag_attributes
  end

private

  def flags_to_enable
    feature_flag_attributes.select { |flag| flag_ticked?(flag) }
  end

  def flag_ticked?(flag)
    ActiveModel::Type::Boolean.new.cast(public_send(flag)) == true
  end
end
