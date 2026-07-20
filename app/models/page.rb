class Page < ApplicationRecord
  extend Mobility
  before_destroy :destroy_secondary_skip_conditions

  belongs_to :form
  has_many :routing_conditions, class_name: "Condition", foreign_key: "routing_page_id", dependent: :destroy
  has_many :check_conditions, class_name: "Condition", foreign_key: "check_page_id", dependent: :destroy
  has_many :goto_conditions, class_name: "Condition", foreign_key: "goto_page_id", dependent: :destroy
  has_many :exit_pages, foreign_key: :question_page_id, dependent: :destroy

  acts_as_list scope: :form

  translates :question_text,
             :hint_text,
             :answer_settings,
             :page_heading,
             :guidance_markdown

  ANSWER_TYPES = %w[name organisation_name email phone_number national_insurance_number address date selection number text file].freeze

  ANSWER_TYPES_WITHOUT_SETTINGS = %w[organisation_name email phone_number national_insurance_number number].freeze

  ANSWER_TYPES_WITH_SETTINGS = %w[selection text date address name].freeze

  validates :question_text, presence: true
  validates :question_text, length: { maximum: 250 }

  validates :hint_text, length: { maximum: 500 }

  validates :answer_type, presence: true, inclusion: { in: ANSWER_TYPES }
  validate :guidance_fields_presence
  validates :page_heading, length: { maximum: 250 }
  validate :guidance_markdown_length_and_tags

  attribute :answer_settings, DataStructType.new
  # Open the Model class used for translations and make the same change to the answer_settings attribute
  class Translation
    attribute :answer_settings, DataStructType.new
  end

  before_create :set_external_id

  def self.create_and_update_form!(...)
    page = Page.new(...)
    page.save_and_update_form
    page
  end

  def destroy_and_update_form!
    form = self.form
    destroy! && form.save_question_changes!
  end

  def save_and_update_form
    return true unless has_changes_to_save?

    ActiveRecord::Base.transaction do
      save!
      form.save_question_changes!

      if answer_type_changed_from_selection_only_one_option || answer_settings_changed_from_only_one_option
        exit_pages.destroy_all
        check_conditions.destroy_all
      end
    end

    true
  end

  def move_page(direction)
    case direction
    when :up
      move_higher
      form.save_question_changes!
    when :down
      move_lower
      form.save_question_changes!
    end
  end

  def next_page
    lower_item&.id
  end

  def has_next_page?
    next_page.present?
  end

  def answer_type_changed_from_selection_only_one_option
    answer_type_previously_was&.to_sym == :selection && answer_type&.to_sym != :selection && answer_settings_previously_was.only_one_option == "true"
  end

  def answer_settings_changed_from_only_one_option
    from_only_one_option = ActiveModel::Type::Boolean.new.cast(answer_settings_previously_was.try(:[], "only_one_option"))
    to_multiple_options = !ActiveModel::Type::Boolean.new.cast(answer_settings.try(:[], "only_one_option"))

    from_only_one_option && to_multiple_options
  end

  def has_routing_errors
    routing_conditions.filter(&:has_routing_errors).any?
  end

  def question_with_number
    "#{position}. #{question_text}"
  end

  def show_optional_suffix?
    is_optional? && answer_type != "selection"
  end

  def as_form_document_step(next_page)
    {
      "id" => external_id,
      "position" => position,
      "next_step_id" => next_page&.external_id,
      "type" => "question",
      "data" => slice(*%w[question_text hint_text answer_type is_optional answer_settings page_heading guidance_markdown is_repeatable]),
      "routing_conditions" => routing_conditions.map(&:as_form_document_condition),
      "exit_pages" => exit_pages.map(&:as_form_document_exit_page),
    }
  end

  def secondary_skip_condition
    check_conditions.where(answer_value: nil).where.not("check_page_id = routing_page_id").first
  end

  def normalise_welsh!
    # If the page has been destroyed, update! will raise an error
    return if destroyed?

    update!(hint_text_cy: nil) if hint_text.blank?

    if page_heading.blank? && guidance_markdown.blank?
      update!(
        page_heading_cy: nil,
        guidance_markdown_cy: nil,
      )
    end

    routing_conditions.each(&:normalise_welsh!)
  end

  def page_position_id
    "page-#{position}"
  end

private

  def guidance_fields_presence
    if page_heading.present? && guidance_markdown.blank?
      errors.add(:guidance_markdown, "must be present when Page Heading is present")
    elsif guidance_markdown.present? && page_heading.blank?
      errors.add(:page_heading, "must be present when Guidance Markdown is present")
    end
  end

  def guidance_markdown_length_and_tags
    return true if guidance_markdown.blank?

    markdown_validation = GovukFormsMarkdown.validate(guidance_markdown)

    return true if markdown_validation[:errors].empty?

    if markdown_validation[:errors].include?(:too_long)
      errors.add(:guidance_markdown, :too_long, count: "4,999")
    end

    tag_errors = markdown_validation[:errors].excluding(:too_long)
    if tag_errors.any?
      errors.add(:guidance_markdown, :unsupported_markdown_syntax, message: "can only contain formatting for links, subheadings(##), bulleted listed (*), or numbered lists(1.)")
    end
  end

  def destroy_secondary_skip_conditions
    return if goto_conditions.empty?

    # We want to delete the secondary skip for the page at the start of the route
    # That association isn't in the database, so we need to dig it out
    # TODO: what if the page owning the routes has more than two routes?
    # https://trello.com/c/ZPFCV1C7/3462-rewrite-destroysecondaryskipconditions-to-handle-a-routing-page-with-more-than-two-routes
    goto_conditions
      .filter { |condition| condition.check_page_id == condition.routing_page_id }
      .map(&:check_page)
      .flat_map(&:check_conditions)
      .filter { |condition| condition.check_page_id != condition.routing_page_id }
      .each(&:destroy!)
  end

  def set_external_id
    self.external_id ||= ExternalIdProvider.generate_unique_id_for(Page)
  end
end
