class Forms::WelshTranslationInput < Forms::MarkCompleteInput
  include TextInputHelper
  include ActiveModel::Attributes

  attr_accessor :form, :page_translations

  attribute :mark_complete

  attribute :name_cy
  attribute :privacy_policy_url_cy
  attribute :support_email_cy
  attribute :support_phone_cy
  attribute :support_url_cy
  attribute :support_url_text_cy
  attribute :declaration_markdown_cy
  attribute :what_happens_next_markdown_cy
  attribute :payment_url_cy

  validates :name_cy, presence: true, if: -> { marked_complete? }
  validates :name_cy, length: { maximum: 500 }, if: -> { name_cy.present? }

  validates :privacy_policy_url_cy, presence: true, if: -> { marked_complete? && form.privacy_policy_url.present? }
  validates :privacy_policy_url_cy, url: true, if: -> { privacy_policy_url_cy.present? }
  validates :privacy_policy_url_cy, exclusion: { in: %w[https://www.gov.uk/help/privacy-notice] }, if: -> { privacy_policy_url_cy.present? }

  validates :support_email_cy, presence: true, if: -> { marked_complete? && form_has_support_email? }
  validates :support_email_cy, email_address: true, allowed_email_domain: true, if: -> { support_email_cy.present? }

  validates :support_phone_cy, presence: true, if: -> { marked_complete? && form_has_support_phone? }
  validates :support_phone_cy, length: { maximum: 500 }, if: -> { support_phone_cy.present? }

  validates :support_url_cy, presence: true, if: -> { marked_complete? && form_has_support_url? }
  validates :support_url_cy, url: true, length: { maximum: 120 }, if: -> { support_url_cy.present? }

  validates :support_url_text_cy, presence: true, if: -> { marked_complete? && form_has_support_url? }
  validates :support_url_text_cy, length: { maximum: 120 }, if: -> { support_url_text_cy.present? }

  validates :declaration_markdown_cy, presence: true, if: -> { marked_complete? && form_has_declaration? }
  validates :declaration_markdown_cy, length: { maximum: 2000 }, if: -> { declaration_markdown_cy.present? }

  validates :what_happens_next_markdown_cy, presence: true, if: -> { marked_complete? && form.what_happens_next_markdown.present? }
  validates :what_happens_next_markdown_cy, markdown: { allow_headings: false }, if: -> { what_happens_next_markdown_cy.present? }

  validates :payment_url_cy, presence: true, if: -> { marked_complete? && form_has_payment_url? }
  validates :payment_url_cy, payment_link: true, if: -> { payment_url_cy.present? }

  validate :page_translations_valid

  def initialize(attributes = {})
    @form = attributes.delete(:form)
    super
    @page_translations ||= []
  end

  def page_translations_attributes=(attributes)
    # Get all submitted page IDs from the params hash.
    submitted_page_ids = attributes.values.map { |attrs| attrs["id"] }.compact

    # lookup hash for efficiency
    pages_by_id = form.pages.where(id: submitted_page_ids).includes(:routing_conditions).index_by(&:id)

    self.page_translations = attributes.values.map { |page_attrs|
      page_id = page_attrs["id"].to_i
      page_object = pages_by_id[page_id]

      # skip the page if it doesn't belong to the form
      next unless page_object

      Forms::WelshPageTranslationInput.new(page_attrs.symbolize_keys.merge(page: page_object))
    }.compact
  end

  def submit
    return false if invalid?

    form.name_cy = name_cy
    form.declaration_markdown_cy = form_has_declaration? ? declaration_markdown_cy : nil
    form.payment_url_cy = form_has_payment_url? ? payment_url_cy : nil
    form.privacy_policy_url_cy = privacy_policy_url_cy
    form.support_email_cy = form_has_support_email? ? support_email_cy : nil
    form.support_phone_cy = form_has_support_phone? ? support_phone_cy : nil

    if form_has_support_url?
      form.support_url_cy = support_url_cy
      form.support_url_text_cy = support_url_text_cy
    else
      form.support_url_cy = nil
      form.support_url_text_cy = nil
    end

    form.what_happens_next_markdown_cy = what_happens_next_markdown_cy

    page_translations.presence&.each(&:submit)

    form.welsh_completed = mark_complete

    # We add :cy to the available languages so that the welsh form can be
    # previewed. This means that if mark_complete is false, welsh form docs
    # will be generated.
    form.available_languages = %w[en cy]

    form.save_draft!
  end

  def assign_form_values
    self.name_cy = form.name_cy
    self.privacy_policy_url_cy = form.privacy_policy_url_cy
    self.support_email_cy = form.support_email_cy
    self.support_phone_cy = form.support_phone_cy
    self.support_url_cy = form.support_url_cy
    self.support_url_text_cy = form.support_url_text_cy
    self.declaration_markdown_cy = form.declaration_markdown_cy
    self.what_happens_next_markdown_cy = form.what_happens_next_markdown_cy
    self.payment_url_cy = form.payment_url_cy

    self.mark_complete = form.try(:welsh_completed)

    self.page_translations = form.pages.map do |page|
      Forms::WelshPageTranslationInput.new(page:).assign_page_values
    end

    self
  end

  def blanked?
    all_fields_empty? && page_translations.all?(&:blanked?)
  end

  def all_fields_empty?
    attributes.except!("mark_complete").values.all?(&:blank?)
  end

  def form_has_declaration?
    form.declaration_markdown.present?
  end

  def form_has_payment_url?
    form.payment_url.present?
  end

  def form_has_support_url?
    form.support_url.present?
  end

  def form_has_support_phone?
    form.support_phone.present?
  end

  def form_has_support_email?
    form.support_email.present?
  end

  def form_has_support_information?
    form_has_support_email? || form_has_support_phone? || form_has_support_url?
  end

  def form_has_what_happens_next?
    form.what_happens_next_markdown.present?
  end

  def form_has_privacy_information?
    form.privacy_policy_url.present?
  end

  def page_translations_valid
    return if page_translations.nil?

    # We pass :mark_complete as the validation context so the page_translations
    # can validate differently depending on whether the form is marked complete
    validation_context = marked_complete? ? :mark_complete : nil

    page_translations.each do |page_translation|
      page_translation.validate(validation_context)

      page_translation.errors.each do |error|
        errors.import(error, { attribute: "page_#{page_translation.page.position}_#{error.attribute}".to_sym })
      end
    end
  end
end
