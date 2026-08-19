class Forms::RouteInput < BaseInput
  include ActiveModel::Attributes

  attribute :id # id of the Condition
  attribute :page_id, :integer
  attribute :goto, GotoValueType.new
  attribute :answer_value

  attr_accessor :page, :goto_page, :goto_options

  validate :route_is_not_backwards

  def goes_to_default_next_page?
    goto.is_a?(GotoValue::DefaultValue)
  end

  def goes_to_end_of_form?
    goto.is_a?(GotoValue::EndOfFormValue)
  end

  def goes_to_page?
    goto.is_a?(GotoValue::Page)
  end

  def condition_attributes
    case goto
    when GotoValue::DefaultValue
      nil
    when GotoValue::EndOfFormValue
      { goto_page_id: nil, skip_to_end: true, check_page_id: page.id }
    when GotoValue::Page
      { goto_page_id: goto.page_id, skip_to_end: false, check_page_id: page.id }
    end
  end

  def label
    if Forms::RoutesInput.route_with_selection_options?(page)
      answer_value_label = answer_value == Condition::NONE_OF_THE_ABOVE ? I18n.t("page_conditions.none_of_the_above") : answer_value
      return { text: "If option #{option_index} (#{answer_value_label}), go to:" }
    end

    { text: "After question #{page.position}, go to:" }
  end

private

  def route_is_not_backwards
    return if !goes_to_page? || goto_page.nil?

    return if goto_page.position > page.position

    errors.add(:goto, :backwards_route, message: error_message_for_backwards_route)
  end

  def error_message_for_backwards_route
    if Forms::RoutesInput.route_with_selection_options?(page)
      I18n.t("errors.routes.cannot_route_backwards_from_selection_page", question_number: page.position, option_number: option_index)
    else
      I18n.t("errors.routes.cannot_route_backwards_from_generic_page", question_number: page.position)
    end
  end

  def option_index
    if answer_value == Condition::NONE_OF_THE_ABOVE
      page.answer_settings.selection_options.length + 1
    else
      page.answer_settings.selection_options.find_index { |option| option["value"] == answer_value } + 1
    end
  end
end
