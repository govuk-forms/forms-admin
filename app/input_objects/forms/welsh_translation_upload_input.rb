class Forms::WelshTranslationUploadInput < BaseInput
  include ActiveModel::Attributes

  FILE_TYPES = %w[
    text/csv
  ].freeze
  MAX_SIZE_IN_MB = 10

  attr_accessor :form, :file

  attribute :error_row_number

  validates :file, presence: true, file_content_type: { in: FILE_TYPES }
  validate :validate_file_size

  def read_file
    return false if invalid?

    WelshCsvImportService.new(file, form).read
  rescue CSV::MalformedCSVError
    errors.add(:file, :malformed)
    false
  rescue WelshCsvImportService::InvalidEncodingError
    errors.add(:file, :invalid_encoding)
    false
  rescue WelshCsvImportService::InvalidHeadersError
    errors.add(:file, :invalid_headers)
    false
  rescue WelshCsvImportService::DifferentNumberOfSelectionOptionsError => e
    errors.add(:file, :different_number_of_selection_options, question_number: e.question_number)
    false
  rescue WelshCsvImportService::SelectionOptionsMismatchError => e
    errors.add(:file, :selection_options_mismatch, question_number: e.question_number)
    false
  rescue WelshCsvImportService::SelectionOptionTranslationsMissingError => e
    errors.add(:file, :selection_options_translations_missing, question_number: e.question_number)
    false
  rescue WelshCsvImportService::FormContentNotFoundError => e
    errors.add(:file, :form_content_not_found)
    self.error_row_number = e.row_number
    false
  rescue WelshCsvImportService::QuestionTextMismatchError => e
    # the error message is the same as for form_content_not_found, but we use a separate key to distinguish in the logs
    errors.add(:file, :question_text_mismatch)
    self.error_row_number = e.row_number
    false
  rescue WelshCsvImportService::ExitPageHeadingMismatchError => e
    errors.add(:file, :exit_page_heading_mismatch)
    self.error_row_number = e.row_number
    false
  end

private

  def validate_file_size
    if file.present? && file.size > MAX_SIZE_IN_MB.megabytes
      errors.add(:file, :too_big)
    end
  end
end
