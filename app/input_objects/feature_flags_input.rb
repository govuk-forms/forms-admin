class FeatureFlagsInput < BaseInput
  attr_reader :record, :flags

  # `record` is the group or organisation the flags belong to, and `submitted` is
  # the submitted params for this input.
  def initialize(record:, submitted: {})
    super()

    @record = record
    # The flags depend on the app settings and the record's schema, so look them up
    # once here rather than each time they are needed.
    @flags = record.class.feature_flag_attributes
    @ticked_flags = flags.select { |flag| ActiveModel::Type::Boolean.new.cast(submitted[flag]) == true }
  end

  def submit
    return false if invalid?

    # Feature flags can only be switched on, never off. Enabling a feature can change
    # a group's or organisation's forms or data in ways that would need to be manually
    # reversed before it is safe to disable, so we only ever turn flags on here.
    record.assign_attributes(@ticked_flags.index_with(true))
    @flags_changed = record.changed?

    return true if record.save

    errors.merge!(record.errors)
    record.restore_attributes(@ticked_flags)
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
    flag_locked?(flag) || @ticked_flags.include?(flag)
  end
end
