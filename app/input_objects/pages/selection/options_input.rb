class Pages::Selection::OptionsInput < Pages::Selection::BaseOptionsInput
  DEFAULT_OPTIONS = { selection_options: [{ name: "" }, { name: "" }] }.freeze

  attr_accessor :selection_options

  validate :selection_options, :validate_selection_options
  validates :include_none_of_the_above, inclusion: { in: INCLUDE_NONE_OF_THE_ABOVE_OPTIONS }

  def assign_form_values
    self.selection_options = draft_question.answer_settings[:selection_options].map { |option| { name: option[:name] } }
    self.include_none_of_the_above = selected_none_of_the_above_option(draft_question)
  end

  def add_another
    selection_options.append({ name: "" })
  end

  def remove(index)
    selection_options.delete_at(index)
  end

  def selection_options_form_objects
    selection_options.map { |option| OpenStruct.new(name: option[:name]) }
  end

  def can_add_more_options?
    selection_options.count < maximum_options
  end

private

  def validate_selection_options
    filter_out_blank_options

    return errors.add(:selection_options, :minimum) if selection_options.length < 2
    return errors.add(:selection_options, maximum_error_type) if selection_options.length > maximum_options

    errors.add(:selection_options, :uniqueness) if selection_options.uniq.length != selection_options.length
  end

  def filter_out_blank_options
    self.selection_options = selection_options.filter { |option| option[:name].present? }
  end
end
