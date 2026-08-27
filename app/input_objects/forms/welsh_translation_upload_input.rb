class Forms::WelshTranslationUploadInput < BaseInput
  FILE_TYPES = %w[
    text/csv
  ].freeze
  MAX_SIZE_IN_MB = 10

  attr_accessor :form, :file

  validates :file, presence: true, file_content_type: { in: FILE_TYPES }
  validate :validate_file_size

  def read_file
    return false if invalid?

    WelshCsvImportService.new(file, form).read
  rescue CSV::MalformedCSVError
    errors.add(:file, :malformed)
    false
  rescue WelshCsvImportService::InvalidHeadersError
    errors.add(:file, :invalid_headers)
    false
  end

private

  def validate_file_size
    if file.present? && file.size > MAX_SIZE_IN_MB.megabytes
      errors.add(:file, :too_big)
    end
  end
end
