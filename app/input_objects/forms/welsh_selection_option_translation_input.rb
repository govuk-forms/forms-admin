class Forms::WelshSelectionOptionTranslationInput < BaseInput
  include TextInputHelper
  include ActionView::Helpers::FormTagHelper
  include ActiveModel::Attributes

  NAME_MAX_LENGTH = 250

  attr_accessor :selection_option, :page

  attribute :id, :integer
  attribute :name_cy

  validate :name_present?, on: :mark_complete
  validate :name_length, if: -> { name_cy.present? }

  def initialize(attributes = {})
    @selection_option = attributes.delete(:selection_option) if attributes.key?(:selection_option)
    @page = attributes.delete(:page) if attributes.key?(:page)
    super
  end

  def assign_selection_option_values
    return self unless selection_option

    self.name_cy = selection_option.name
    self
  end

  def assign_selection_option_values_from_csv_values(csv_values)
    return self unless selection_option

    spreadsheet_id = page_content_id(page.id, "option_#{index}")
    self.name_cy = csv_values[spreadsheet_id] if csv_values.key?(spreadsheet_id)
    self
  end

  def as_selection_option
    { name: name_cy, value: selection_option.value }
  end

  def form_field_id(attribute)
    field_id(:forms_welsh_selection_option_translation_input, page.id, :selection_options_cy, id, attribute)
  end

  def selection_number
    id + 1
  end

  def question_number
    page.position
  end

  def all_fields_empty?
    name_cy.blank?
  end

private

  def name_present?
    if name_cy.blank?
      errors.add(:name_cy, :blank, selection_number:, question_number:, url: "##{form_field_id(:name_cy)}")
    end
  end

  def name_length
    return if name_cy.length <= NAME_MAX_LENGTH

    errors.add(:name_cy, :too_long, selection_number:, question_number:, count: NAME_MAX_LENGTH, url: "##{form_field_id(:name_cy)}")
  end
end
