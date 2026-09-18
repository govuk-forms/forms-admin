class Pages::QuestionInput < BaseInput
  attr_accessor :question_text, :hint_text, :is_optional, :answer_type, :draft_question, :is_repeatable, :form_id

  # TODO: We could lose these attributes once we have a 'Check your question' page
  # https://trello.com/c/uSkzB4Sl/3-create-check-your-question-page
  attr_accessor :answer_settings, :page_heading, :guidance_markdown

  attr_reader :selection_options # only used for displaying error

  validates :draft_question, presence: true
  validate :validate_question_text_presence
  validate :validate_question_text_length
  validates :hint_text, length: { maximum: 500 }
  validates :is_optional, inclusion: { in: %w[false true] }
  validates :is_repeatable, inclusion: { in: %w[false true] }
  validate :validate_number_of_selection_options

  def submit
    return false if invalid?

    prepare_for_save

    attrs = {
      form_id:,
      question_text:,
      hint_text:,
      is_optional:,
      is_repeatable:,
      answer_settings:,
      page_heading:,
      guidance_markdown:,
      answer_type:,
    }

    if draft_question.form.available_languages.include?("cy")
      attrs[:answer_settings_cy] = answer_settings_cy
    end

    Page.create_and_update_form!(**attrs)
  end

  def update_page(page)
    return false if invalid?

    prepare_for_save

    attrs = {
      question_text:,
      hint_text:,
      is_optional:,
      is_repeatable:,
      answer_settings:,
      page_heading:,
      guidance_markdown:,
      answer_type:,
    }

    if draft_question.form.available_languages.include?("cy")
      attrs[:answer_settings_cy] = answer_settings_cy(page)
    end

    page.assign_attributes(**attrs)

    ActiveRecord::Base.transaction do
      if FeatureService.new(group: draft_question.form&.group).enabled?(:multiple_branches)
        remove_conditions_without_valid_answer_values(page)
        ensure_conditions_match_question_type(page)
      end
      page.save_and_update_form
    end
  end

  def update_draft_question!
    draft_question.update!(
      question_text:,
      hint_text:,
      is_optional:,
      is_repeatable:,
    )
  end

  def default_options
    [OpenStruct.new(id: "false"), OpenStruct.new(id: "true")]
  end

  def repeatable_options
    [OpenStruct.new(id: "true"), OpenStruct.new(id: "false")]
  end

  def validate_number_of_selection_options
    return if draft_question.nil?
    return unless @draft_question.answer_type == "selection"
    return unless @draft_question.answer_settings[:only_one_option] == "false" &&
      @draft_question.answer_settings[:selection_options].length > 30

    errors.add(:selection_options, :too_many_selection_options)
  end

  def validate_question_text_presence
    return if question_text.present?

    translation_key = answer_type == "file" ? :blank_file : :blank
    errors.add(:question_text, translation_key)
  end

  def validate_question_text_length
    return if question_text.blank? || question_text.length <= QuestionTextValidation::QUESTION_TEXT_MAX_LENGTH

    translation_key = answer_type == "file" ? :too_long_file : :too_long
    errors.add(:question_text, translation_key, count: QuestionTextValidation::QUESTION_TEXT_MAX_LENGTH)
  end

private

  def prepare_for_save
    compact_answer_settings
    update_draft_question!
  end

  def compact_answer_settings
    answer_settings.delete(:none_of_the_above_question) if answer_settings[:none_of_the_above_question].blank?
  end

  def answer_settings_cy(page = nil)
    return unless answer_type == "selection"

    answer_settings_cloned = DataStructType.new.cast_value(answer_settings.as_json)

    answer_settings_cloned.selection_options.each.with_index do |selection_option, index|
      welsh_name = page&.answer_settings_cy&.dig("selection_options", index, "name")

      selection_option.name = (welsh_name.presence || "")
    end

    if answer_settings_cloned.none_of_the_above_question.present?
      welsh_none_of_the_above_question = page&.answer_settings_cy&.dig("none_of_the_above_question", "question_text")
      answer_settings_cloned.none_of_the_above_question.question_text = welsh_none_of_the_above_question || ""
    end

    answer_settings_cloned
  end

  def remove_conditions_without_valid_answer_values(page)
    return unless Forms::RoutesInput.route_with_selection_options?(page)

    valid_answer_values = page.answer_settings[:selection_options].map { it[:value] }
    valid_answer_values << Condition::NONE_OF_THE_ABOVE if page.is_optional

    page.routing_conditions.where.not(answer_value: valid_answer_values).destroy_all
  end

  def ensure_conditions_match_question_type(page)
    if Forms::RoutesInput.route_with_selection_options?(page)
      generic_condition = page.routing_conditions.where(answer_value: nil)&.first

      return if generic_condition.nil?

      attributes = if generic_condition.skip_to_end?
                     {
                       goto_page_id: nil,
                       skip_to_end: true,
                       check_page_id: page.id,
                     }
                   else
                     {
                       goto_page_id: generic_condition.goto_page_id,
                       skip_to_end: false,
                       check_page_id: page.id,
                     }
                   end

      options = page.answer_settings[:selection_options].map { |option| option["value"] }
      options << Condition::NONE_OF_THE_ABOVE if page.is_optional

      options.each do |option|
        condition_for_option = Condition.find_or_initialize_by(routing_page_id: page.id, answer_value: option)
        condition_for_option.assign_attributes(attributes)
        condition_for_option.save!
      end

      generic_condition.destroy!
    end
  end
end
