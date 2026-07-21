class Forms::SubmissionAttachmentsInput < BaseInput
  attr_accessor :form, :submission_format

  SUBMISSION_FORMATS = %w[csv json].freeze

  validates :submission_format, presence: true
  validate :valid_submission_format, if: -> { submission_format.present? }

  def submit
    return false if invalid?

    delivery_configuration = form.immediate_email_delivery_configuration
    raise NotFoundError if delivery_configuration.nil?

    delivery_configuration.formats = submission_format.compact_blank
    delivery_configuration.save!
    form.delivery_configurations.reload

    form.save_draft!
  end

  def assign_form_values
    self.submission_format = form.immediate_email_delivery_configuration&.formats || []
    self
  end

private

  def valid_submission_format
    errors.add(:base, :invalid_submission_format) unless (submission_format.compact_blank - SUBMISSION_FORMATS).empty?
  end
end
