class Forms::WelshTranslationUploadInput < BaseInput
  attr_accessor :file

  validates :file, presence: true

  def read_file
    return false if invalid?

    csv_data = file.read.force_encoding("UTF-8")
    WelshCsvImportService.new(csv_data).read
  rescue CSV::MalformedCSVError, WelshCsvImportService::InvalidHeadersError
    errors.add(:file, :invalid_csv)
    false
  end
end
