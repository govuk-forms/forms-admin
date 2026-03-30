class Form < ApplicationRecord
  include FormStateMachine
  extend Mobility

  self.ignored_columns += [:language]

  SUPPORTED_LANGUAGES = %w[en cy].freeze

  has_many :pages, -> { order(position: :asc) }, dependent: :destroy
  has_one :form_submission_email, dependent: :destroy
  has_one :group_form, dependent: :destroy
  has_many :form_documents, dependent: :destroy
  has_one :live_form_document, -> { where tag: "live", language: :en }, class_name: "FormDocument"
  has_one :live_welsh_form_document, -> { where tag: "live", language: :cy }, class_name: "FormDocument"
  has_one :archived_form_document, -> { where tag: "archived", language: :en }, class_name: "FormDocument"
  has_one :archived_welsh_form_document, -> { where tag: "archived", language: :cy }, class_name: "FormDocument"
  has_one :draft_welsh_form_document, -> { where tag: "draft", language: :cy }, class_name: "FormDocument"
  has_one :draft_form_document, -> { where tag: "draft", language: :en }, class_name: "FormDocument"
  has_many :conditions, through: :pages, source: :routing_conditions

  translates :name,
             :privacy_policy_url,
             :support_email,
             :support_phone,
             :support_url,
             :support_url_text,
             :declaration_text,
             :declaration_markdown,
             :what_happens_next_markdown,
             :payment_url

  enum :submission_type, {
    email: "email",
    s3: "s3",
  }

  # ActiveRecord doesn't support enums with arrays
  # enum :submission_format, {
  #   csv: "csv",
  #   json: "json",
  # }

  validates :name, presence: true
  validates :payment_url, url: true, allow_blank: true
  validate :marking_complete_with_errors
  validates :submission_type, presence: true
  validates :available_languages, presence: true, inclusion: { in: SUPPORTED_LANGUAGES }
  validates :submission_email, email_address: { message: :invalid_email }, allow_blank: true
  validates :support_email, email_address: { message: :invalid_email }, allow_blank: true

  after_create :set_external_id
  after_update :update_draft_form_document
  ATTRIBUTES_NOT_IN_FORM_DOCUMENT = %i[state external_id pages question_section_completed declaration_section_completed share_preview_completed welsh_completed].freeze

  def save_question_changes!
    self.question_section_completed = false
    # Make sure the updated_at is updated as we use this to determine if the form has changed in forms-runner.
    touch unless changed?
    save_draft!
  end

  def save_draft!
    if live?
      create_draft_from_live_form!
    elsif archived?
      create_draft_from_archived_form!
    else
      save!
    end
  end

  def has_draft_version
    draft? || live_with_draft? || archived_with_draft?
  end

  def has_live_version
    live? || live_with_draft?
  end

  alias_method :is_live?, :has_live_version

  def has_been_archived
    archived? || archived_with_draft?
  end

  alias_method :is_archived?, :has_been_archived

  # We need to include the splat operator as second argument,
  # since Mobility expects this when using locale setters like `name_cy=`
  def name=(val, ...)
    super

    # Always set form_slug using the English name
    self[:form_slug] = name.present? ? name_en.parameterize : ""
  end

  # form_slug is always set based on name
  def form_slug=(slug); end

  def has_routing_errors
    pages.filter(&:has_routing_errors).any?
  end

  alias_method :has_routing_errors?, :has_routing_errors

  def marking_complete_with_errors
    errors.add(:base, :has_validation_errors, message: "Form has routing validation errors") if question_section_completed && has_routing_errors
  end

  def ready_for_live
    task_status_service.mandatory_tasks_completed?
  end

  def all_ready_for_live?
    ready_for_live
  end

  delegate :incomplete_tasks, to: :task_status_service

  delegate :task_statuses, to: :task_status_service

  def group
    group_form&.group
  end

  def qualifying_route_pages
    max_routes_per_page = 2

    condition_counts = conditions.group_by(&:check_page_id).transform_values(&:length)

    pages.filter do |page|
      page.answer_type == "selection" &&
        page.answer_settings.only_one_option == "true" &&
        page.position != pages.length &&
        condition_counts.fetch(page.id, 0) < max_routes_per_page &&
        page.routing_conditions.none?(&:secondary_skip?)
    end
  end

  def has_no_remaining_routes_available?
    qualifying_route_pages.none? && has_routing_conditions
  end

  def all_incomplete_tasks
    incomplete_tasks
  end

  def all_task_statuses
    task_statuses
  end

  def page_number(page)
    return pages.length + 1 if page.nil?
    return pages.length + 1 if page.id.nil?

    index = pages.index { |existing_page| existing_page.id == page.id }
    (index.nil? ? pages.length : index) + 1
  end

  def email_confirmation_status
    # Email set before confirmation feature introduced
    return :email_set_without_confirmation if submission_email.present? && form_submission_email.blank?

    if form_submission_email.present?
      if form_submission_email.confirmed? || submission_email == form_submission_email.temporary_submission_email
        :confirmed
      else
        :sent
      end
    else
      :not_started
    end
  end

  def file_upload_question_count
    pages.count { |p| p.answer_type.to_sym == :file }
  end

  after_destroy do
    group_form&.destroy
  end

  def as_form_document(live_at: nil, language: :en)
    content = as_json(
      except: ATTRIBUTES_NOT_IN_FORM_DOCUMENT,
      methods: %i[start_page steps],
    )
    content["form_id"] = content.delete("id").to_s
    content["live_at"] = live_at if live_at.present?
    content["language"] = language.to_s if language.present?
    content
  end

  def has_welsh_translation?
    available_languages.include?("cy")
  end

  def normalise_welsh!
    return unless available_languages.include?("cy")

    self.declaration_markdown_cy = nil if declaration_markdown.blank?
    self.payment_url_cy = nil if payment_url.blank?
    self.support_email_cy = nil if support_email.blank?
    self.support_phone_cy = nil if support_phone.blank?
    self.support_url_cy = nil if support_url.blank?
    self.support_url_text_cy = nil if support_url_text.blank?
    self.what_happens_next_markdown_cy = nil if what_happens_next_markdown.blank?

    pages.each(&:normalise_welsh!)
  end

  # Pass in the previous state rather than getting it from #state_previously_was as the Form may have been updated in a
  # separate instance
  def draft_created?(previous_state)
    return false if state.to_sym == previous_state.to_sym

    (previous_state.to_sym == :live && live_with_draft?) ||
      (previous_state.to_sym == :archived && archived_with_draft?)
  end

  def can_make_language_live?(language:)
    return can_make_english_version_live? if language == "en"

    can_make_welsh_version_live? if language == "cy"
  end

private

  def set_external_id
    update(external_id: id)
  end

  def update_draft_form_document
    FormDocumentSyncService.new(self).update_draft_form_document
  end

  def task_status_service
    # TODO: refactor this in favour of dependency injection
    # https://trello.com/c/TVN9BNxQ/3448-refactor-formtaskstatusservice-to-use-dependency-injection
    # it can also lead to use of `allow_any_instance_of` in testing
    @task_status_service ||= TaskStatusService.new(form: self)
  end

  def has_routing_conditions
    pages.filter { |p| p.routing_conditions.any? }.any?
  end

  def group_form
    GroupForm.find_by_form_id(id)
  end

  def steps
    ordered_pages = pages.includes(:routing_conditions).to_a
    ordered_pages.map.with_index do |page, index|
      next_page = ordered_pages.fetch(index + 1, nil)
      page.as_form_document_step(next_page)
    end
  end

  def start_page
    pages&.first&.external_id
  end

  # callbacks for FormStateMachine
  def after_create_draft
    update_columns(share_preview_completed: false)
  end

  def before_make_live
    self.first_made_live_at = current_time_from_proper_timezone if first_made_live_at.nil?
  end

  def after_make_live
    FormDocumentSyncService.new(self).synchronize_live_form
  end

  def before_make_english_live
    before_make_live
  end

  def after_make_english_live
    FormDocumentSyncService.new(self).synchronize_live_english_form
  end

  def before_make_welsh_live
    before_make_live
  end

  def after_make_welsh_live
    FormDocumentSyncService.new(self).synchronize_live_welsh_form
  end

  def can_make_english_version_live?
    draft? && ready_for_live && live_form_document.blank? && live_welsh_form_document.blank?
  end

  def can_make_welsh_version_live?
    has_live_version && ready_for_live && live_form_document.present? && live_welsh_form_document.blank?
  end

  def after_archive
    FormDocumentSyncService.new(self).synchronize_archived_form
  end
end
