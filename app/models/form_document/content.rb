class FormDocument::Content
  include ActiveModel::API
  include ActiveModel::Attributes

  attr_reader :steps

  attribute :form_id, :integer
  attribute :live_at, :datetime
  attribute :first_made_live_at, :datetime
  attribute :name, :string
  attribute :available_languages, array: true
  attribute :language, :string
  attribute :form_slug, :string
  attribute :created_at, :datetime
  attribute :creator_id, :datetime
  attribute :start_page, :integer
  attribute :updated_at, :datetime
  attribute :payment_url, :string
  attribute :brand_id, :string
  attribute :support_url, :string
  attribute :support_email, :string
  attribute :support_phone, :string
  attribute :s3_bucket_name, :string
  attribute :submission_type, :string
  attribute :submission_format, array: true
  attribute :declaration_text, :string
  attribute :declaration_markdown, :string
  attribute :s3_bucket_region, :string
  attribute :submission_email, :string
  attribute :support_url_text, :string
  attribute :privacy_policy_url, :string
  attribute :s3_bucket_aws_account_id, :string
  attribute :what_happens_next_markdown, :string
  attribute :send_daily_submission_batch, :boolean
  attribute :send_weekly_submission_batch, :boolean
  attribute :send_copy_of_answers, :string

  alias_attribute :id, :form_id

  def initialize(attributes = {})
    @steps = attributes.fetch("steps", []).map { |step| FormDocument::Step.new(**step) }
    attributes.slice!(*self.class.attribute_names)
    super
  end

  def made_live_date
    first_made_live_at&.to_date
  end

  def self.from_form_document(form_document)
    new(**form_document.content)
  end

  def has_welsh_translation?
    available_languages.present? && available_languages.include?("cy")
  end
end
