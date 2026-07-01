class Forms::WelshTranslationUploadInput < BaseInput
  attr_accessor :file

  validates :file, presence: true
  validate :validate_file_type

  FILE_TYPES = %w[
    text/csv
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.oasis.opendocument.spreadsheet
  ].freeze

  def read_file
    return false if invalid?

    WelshSpreadsheetImportService.new(file).read
  rescue CSV::MalformedCSVError, WelshSpreadsheetImportService::InvalidHeadersError
    errors.add(:file, :invalid_csv)
    false
  end

  def validate_file_type
    if file.present? && FILE_TYPES.exclude?(file.content_type)
      errors.add(:file, :disallowed_type)
    end
  end
end
