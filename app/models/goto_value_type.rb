class GotoValueType < ActiveModel::Type::Value
  def cast(value)
    # If the value is already the correct object type, just return it.
    return value if value.is_a?(GotoValue::DefaultValue) ||
      value.is_a?(GotoValue::EndOfFormValue) ||
      value.is_a?(GotoValue::Page) ||
      value.is_a?(GotoValue::ExitPage)

    # Otherwise, parse it from a string.
    string_value = value.to_s
    return nil if string_value.blank?

    GotoValue.from_string(string_value)
  end

  def serialize(value)
    value&.to_s
  end

  def type
    :goto_value
  end
end
