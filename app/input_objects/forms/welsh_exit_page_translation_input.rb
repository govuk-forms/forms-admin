class Forms::WelshExitPageTranslationInput < BaseInput
  include ActionView::Helpers::FormTagHelper
  include ActiveModel::Attributes
  include WelshTranslationContentLabels

  attr_accessor :exit_page, :position

  attribute :id
  attribute :position

  attribute :heading_cy
  attribute :markdown_cy

  validate :heading_cy_present?, on: :mark_complete
  validate :heading_cy_length, if: -> { heading_cy.present? }

  validate :markdown_cy_present?, on: :mark_complete
  validate :markdown_cy_length_and_tags, if: -> { markdown_cy.present? }

  def initialize(attributes = {})
    @exit_page = attributes.delete(:exit_page) if attributes.key?(:exit_page)
    @position = attributes.delete(:position)
    super
    self.id ||= @exit_page&.id
  end

  def submit
    return false if invalid?

    exit_page.markdown_cy = markdown_cy
    exit_page.heading_cy = heading_cy

    exit_page.save!
  end

  def assign_exit_page_values
    return self unless exit_page

    self.markdown_cy = exit_page.markdown_cy
    self.heading_cy = exit_page.heading_cy

    self
  end

  def assign_from_spreadsheet(data)
    assign_exit_page_values

    %i[heading markdown].each do |attr|
      content_label = exit_page_label(exit_page.question_page, position, attr)
      send(:"#{attr}_cy=", data[content_label]) if data.key?(content_label) && data[content_label].present?
    end

    self
  end

  def form_field_id(attribute)
    field_id(:forms_welsh_exit_page_translation_input, exit_page.id, :exit_page_translations, attribute)
  end

  def heading_cy_present?
    if heading_cy.blank?
      errors.add(:heading_cy, :blank, question_number: page.position, url: "##{form_field_id(:heading_cy)}")
    end
  end

  def heading_cy_length
    return if heading_cy.length <= 250

    errors.add(:heading_cy, :too_long, question_number: page.position, count: 250, url: "##{form_field_id(:heading_cy)}")
  end

  def markdown_cy_present?
    if markdown_cy.blank?
      errors.add(:markdown_cy, :blank, question_number: page.position, url: "##{form_field_id(:markdown_cy)}")
    end
  end

  def markdown_cy_length_and_tags
    markdown_validation = GovukFormsMarkdown.validate(markdown_cy)

    return true if markdown_validation[:errors].empty?

    if markdown_validation[:errors].include?(:too_long)
      errors.add(:markdown_cy, :too_long, count: "4,999", question_number: page.position, url: "##{form_field_id(:markdown_cy)}")
    end

    tag_errors = markdown_validation[:errors].excluding(:too_long)
    if tag_errors.any?
      errors.add(:markdown_cy, :unsupported_markdown_syntax, question_number: page.position, url: "##{form_field_id(:markdown_cy)}")
    end
  end

  def page
    @page ||= exit_page.question_page
  end

  def all_fields_empty?
    attributes.except!("id").values.all?(&:blank?)
  end
end
