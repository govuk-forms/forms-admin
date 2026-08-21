class Forms::WelshConditionTranslationInput < BaseInput
  include ActionView::Helpers::FormTagHelper
  include ActiveModel::Attributes
  include WelshTranslationContentLabels

  attr_accessor :condition

  attribute :id

  attribute :exit_page_heading_cy
  attribute :exit_page_markdown_cy

  validate :exit_page_heading_cy_present?, on: :mark_complete
  validate :exit_page_heading_cy_length, if: -> { exit_page_heading_cy.present? }

  validate :exit_page_markdown_cy_present?, on: :mark_complete
  validate :exit_page_markdown_cy_length_and_tags, if: -> { exit_page_markdown_cy.present? }

  def initialize(attributes = {})
    @condition = attributes.delete(:condition) if attributes.key?(:condition)
    super
    self.id ||= @condition&.id
  end

  def submit
    return false if invalid?

    condition.exit_page_markdown_cy = condition_has_exit_page? ? exit_page_markdown_cy : nil
    condition.exit_page_heading_cy = condition_has_exit_page? ? exit_page_heading_cy : nil

    condition.save!
  end

  def assign_condition_values
    return self unless condition

    self.exit_page_markdown_cy = condition.exit_page_markdown_cy
    self.exit_page_heading_cy = condition.exit_page_heading_cy

    self
  end

  def assign_from_spreadsheet(data)
    assign_condition_values

    %i[exit_page_heading exit_page_markdown].each do |attr|
      content_label = condition_label(condition.routing_page, attr)
      send(:"#{attr}_cy=", data[content_label]) if data.key?(content_label) && data[content_label].present?
    end

    self
  end

  def form_field_id(attribute)
    field_id(:forms_welsh_condition_translation_input, condition.id, :condition_translations, attribute)
  end

  def condition_has_exit_page?
    condition.is_exit_page?
  end

  def exit_page_heading_cy_present?
    if condition_has_exit_page? && exit_page_heading_cy.blank?
      errors.add(:exit_page_heading_cy, :blank, question_number: page.position, url: "##{form_field_id(:exit_page_heading_cy)}")
    end
  end

  def exit_page_heading_cy_length
    return if exit_page_heading_cy.length <= 250

    errors.add(:exit_page_heading_cy, :too_long, question_number: page.position, count: 250, url: "##{form_field_id(:exit_page_heading_cy)}")
  end

  def exit_page_markdown_cy_present?
    if condition_has_exit_page? && exit_page_markdown_cy.blank?
      errors.add(:exit_page_markdown_cy, :blank, question_number: page.position, url: "##{form_field_id(:exit_page_markdown_cy)}")
    end
  end

  def exit_page_markdown_cy_length_and_tags
    markdown_validation = GovukFormsMarkdown.validate(exit_page_markdown_cy)

    return true if markdown_validation[:errors].empty?

    if markdown_validation[:errors].include?(:too_long)
      errors.add(:exit_page_markdown_cy, :too_long, count: "4,999", question_number: page.position, url: "##{form_field_id(:exit_page_markdown_cy)}")
    end

    tag_errors = markdown_validation[:errors].excluding(:too_long)
    if tag_errors.any?
      errors.add(:exit_page_markdown_cy, :unsupported_markdown_syntax, question_number: page.position, url: "##{form_field_id(:exit_page_markdown_cy)}")
    end
  end

  def page
    @page ||= condition.routing_page
  end

  def all_fields_empty?
    attributes.except!("id").values.all?(&:blank?)
  end
end
