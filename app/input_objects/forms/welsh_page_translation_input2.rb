class Forms::WelshPageTranslationInput2 < BaseInput
  include TextInputHelper
  include ActionView::Helpers::FormTagHelper
  include ActiveModel::Attributes

  attr_accessor :exit_page_translations, :selection_options_cy
  attr_reader :page

  attribute :id
  attribute :question_text_cy
  attribute :hint_text_cy
  attribute :page_heading_cy
  attribute :guidance_markdown_cy
  attribute :none_of_the_above_question_cy

  validate :question_text_cy_present?, on: :mark_complete
  validate :question_text_cy_length, if: -> { question_text_cy.present? }

  validate :hint_text_cy_present?, on: :mark_complete
  validate :hint_text_cy_length, if: -> { hint_text_cy.present? }

  validate :page_heading_cy_present?, on: :mark_complete
  validate :page_heading_cy_length, if: -> { page_heading_cy.present? }

  validate :guidance_markdown_cy_present?, on: :mark_complete
  validate :guidance_markdown_cy_length_and_tags, if: -> { guidance_markdown_cy.present? }

  validate :none_of_the_above_question_cy_present?, on: :mark_complete
  validate :none_of_the_above_question_cy_length, if: -> { none_of_the_above_question_cy.present? }

  validate :exit_page_translations_valid?
  validate :selection_options_valid?

  def initialize(attributes = {})
    @page = attributes.delete(:page) if attributes.key?(:page)
    super
    self.id ||= @page&.id
    @exit_page_translations ||= []
    @selection_options_cy ||= []
  end

  def submit
    return false if invalid?

    page.question_text_cy = question_text_cy
    page.hint_text_cy = page_has_hint_text? ? hint_text_cy : nil
    page.page_heading_cy = page_has_page_heading_and_guidance_markdown? ? page_heading_cy : nil
    page.guidance_markdown_cy = page_has_page_heading_and_guidance_markdown? ? guidance_markdown_cy : nil

    exit_page_translations.presence&.each(&:submit)

    page.answer_settings_cy = welsh_answer_settings

    if page_has_none_of_the_above_question?
      page.answer_settings_cy.none_of_the_above_question.question_text = none_of_the_above_question_cy
    end

    if page_has_selection_options?
      page.answer_settings_cy.selection_options = DataStructType.new.cast_value(selection_options_cy.map(&:as_selection_option))
    end

    page.save!
  end

  def assign_page_values
    return self unless page

    self.question_text_cy = page.question_text_cy
    self.hint_text_cy = page.hint_text_cy
    self.page_heading_cy = page.page_heading_cy
    self.guidance_markdown_cy = page.guidance_markdown_cy
    self.none_of_the_above_question_cy = page.answer_settings_cy&.none_of_the_above_question&.question_text

    exit_page_positions = ExitPage.positions_for_page(page)

    self.exit_page_translations = page.exit_pages.map do |exit_page|
      Forms::WelshExitPageTranslationInput.new(exit_page:, position: exit_page_positions[exit_page.id]).assign_exit_page_values
    end

    self.selection_options_cy = welsh_answer_settings&.selection_options&.map&.with_index do |selection_option, index|
      Forms::WelshSelectionOptionTranslationInput.new(selection_option:, page:, id: index).assign_selection_option_values
    end

    self
  end

  def exit_page_translations_attributes=(attributes)
    submitted_exit_page_ids = attributes.values.map { |attrs| attrs["id"] }.compact

    exit_pages_by_id = page.exit_pages.where(id: submitted_exit_page_ids).index_by(&:id)
    exit_page_positions = ExitPage.positions_for_page(page)

    self.exit_page_translations = attributes.values.map { |exit_page_attrs|
      exit_page_id = exit_page_attrs["id"].to_i
      exit_page_position = exit_page_positions[exit_page_id]
      exit_page_object = exit_pages_by_id[exit_page_id]

      # skip the exit page if it doesn't belong to the page
      next unless exit_page_object

      Forms::WelshExitPageTranslationInput.new(exit_page_attrs.symbolize_keys.merge(exit_page: exit_page_object, position: exit_page_position))
    }.compact
  end

  def selection_options_cy_attributes=(attributes)
    self.selection_options_cy = attributes.values.map { |selection_option_attrs|
      # Get the English selection option from the page's answer settings
      selection_option_index = selection_option_attrs["id"].to_i
      english_selection_option = page.answer_settings&.selection_options&.[](selection_option_index)

      # Skip if the selection option doesn't exist in the English version
      next unless english_selection_option

      Forms::WelshSelectionOptionTranslationInput.new(**selection_option_attrs.symbolize_keys, page:, selection_option: english_selection_option)
    }.compact
  end

  def form_field_id(attribute)
    field_id(:forms_welsh_page_translation_input, page.id, :page_translations, attribute)
  end

  def page_has_hint_text?
    page.hint_text.present?
  end

  def page_has_page_heading_and_guidance_markdown?
    page.page_heading.present? && page.guidance_markdown.present?
  end

  def page_has_none_of_the_above_question?
    return false unless page.answer_type == "selection"

    page.answer_settings&.none_of_the_above_question&.question_text.present?
  end

  def question_text_cy_present?
    if question_text_cy.blank?
      errors.add(:question_text_cy, :blank, question_number: page.position, url: "##{form_field_id(:question_text_cy)}")
    end
  end

  def question_text_cy_length
    return if question_text_cy.length <= QuestionTextValidation::QUESTION_TEXT_MAX_LENGTH

    errors.add(:question_text_cy, :too_long, question_number: page.position, count: QuestionTextValidation::QUESTION_TEXT_MAX_LENGTH, url: "##{form_field_id(:question_text_cy)}")
  end

  def hint_text_cy_present?
    if page_has_hint_text? && hint_text_cy.blank?
      errors.add(:hint_text_cy, :blank, question_number: page.position, url: "##{form_field_id(:hint_text_cy)}")
    end
  end

  def hint_text_cy_length
    return if hint_text_cy.length <= 500

    errors.add(:hint_text_cy, :too_long, question_number: page.position, count: 500, url: "##{form_field_id(:hint_text_cy)}")
  end

  def page_heading_cy_present?
    if page_has_page_heading_and_guidance_markdown? && page_heading_cy.blank?
      errors.add(:page_heading_cy, :blank, question_number: page.position, url: "##{form_field_id(:page_heading_cy)}")
    end
  end

  def page_heading_cy_length
    return if page_heading_cy.length <= 250

    errors.add(:page_heading_cy, :too_long, question_number: page.position, count: 250, url: "##{form_field_id(:page_heading_cy)}")
  end

  def guidance_markdown_cy_present?
    if page_has_page_heading_and_guidance_markdown? && guidance_markdown_cy.blank?
      errors.add(:guidance_markdown_cy, :blank, question_number: page.position, url: "##{form_field_id(:guidance_markdown_cy)}")
    end
  end

  def guidance_markdown_cy_length_and_tags
    markdown_validation = GovukFormsMarkdown.validate(guidance_markdown_cy)

    return true if markdown_validation[:errors].empty?

    if markdown_validation[:errors].include?(:too_long)
      errors.add(:guidance_markdown_cy, :too_long, count: "4,999", question_number: page.position, url: "##{form_field_id(:guidance_markdown_cy)}")
    end

    tag_errors = markdown_validation[:errors].excluding(:too_long)
    if tag_errors.any?
      errors.add(:guidance_markdown_cy, :unsupported_markdown_syntax, question_number: page.position, url: "##{form_field_id(:guidance_markdown_cy)}")
    end
  end

  def none_of_the_above_question_cy_present?
    if page_has_none_of_the_above_question? && none_of_the_above_question_cy.blank?
      errors.add(:none_of_the_above_question_cy, :blank, question_number: page.position, url: "##{form_field_id(:none_of_the_above_question_cy)}")
    end
  end

  def none_of_the_above_question_cy_length
    return if none_of_the_above_question_cy.length <= 250

    errors.add(:none_of_the_above_question_cy, :too_long, count: 250, question_number: page.position, url: "##{form_field_id(:none_of_the_above_question_cy)}")
  end

  def form_marked_complete?
    mark_complete == "true"
  end

  def exit_page_translations_valid?
    return if exit_page_translations.nil?

    exit_page_translations.each do |exit_page_translation|
      exit_page_translation.validate(validation_context)

      errors.merge!(exit_page_translation.errors)
    end
  end

  def selection_options_valid?
    return if selection_options_cy.nil?

    # We check for duplicates here rather than in the
    # selection_option_translation because here we can see all the selection options at once

    # This is a list of all the selection options, which we'll use to check for duplicates
    selection_options_without_blanks = selection_options_cy.map(&:name_cy).compact_blank

    # If there are any duplicates, add a single error and link it to the first selection option
    if selection_options_without_blanks.uniq.count != selection_options_without_blanks.count
      first_selection_option_id = selection_options_cy.first.form_field_id(:name_cy)
      errors.add(:selection_options_cy, :uniqueness, duplicate: selection_options_without_blanks.first, question_number: page.position, url: "##{first_selection_option_id}")
    end

    # Import all the errors from the child objects
    selection_options_cy.each do |selection_option_translation|
      selection_option_translation.validate(validation_context)

      selection_option_translation.errors.each do |error|
        errors.import(error, { attribute: "select_option_#{selection_option_translation.id}_#{error.attribute}".to_sym })
      end
    end
  end

  def page_has_selection_options?
    page.answer_type == "selection"
  end

  # We need to normalize the Welsh answer settings to match the English ones.
  # The only answer settings that need translating are the selection options
  # We ensure that welsh answer settings are correct by copying the English
  # ones setting the selection_options using any existing translations we have
  # and emptying any we don't have.
  def welsh_answer_settings
    return nil unless page_has_selection_options?

    answer_settings_cloned = DataStructType.new.cast_value(page.answer_settings.as_json)

    answer_settings_cloned.selection_options.each.with_index do |selection_option, index|
      selection_option.name = page.answer_settings_cy&.dig("selection_options", index, "name") || ""
    end

    if answer_settings_cloned.none_of_the_above_question.present?
      answer_settings_cloned.none_of_the_above_question.question_text = page.answer_settings_cy&.none_of_the_above_question&.question_text || ""
    end

    answer_settings_cloned
  end

  def all_fields_empty?
    attributes.except!("id").values.all?(&:blank?)
  end

  def blanked?
    all_fields_empty? && exit_page_translations.all?(&:all_fields_empty?) && selection_options_cy.all?(&:all_fields_empty?)
  end
end
