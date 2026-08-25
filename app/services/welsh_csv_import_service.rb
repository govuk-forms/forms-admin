class WelshCsvImportService
  include WelshTranslationContentLabels

  class InvalidHeadersError < StandardError; end

  attr_reader :file

  HEADER_INDEXES = {
    WelshCsvService::CONTENT_ID_HEADER => 0,
    WelshCsvService::ENGLISH_CONTENT_HEADER => 1,
    WelshCsvService::WELSH_CONTENT_HEADER => 2,
  }.freeze

  def initialize(file, form)
    @file = file
    @form = form
  end

  def read
    file_content = file.read.force_encoding("UTF-8")
    csv = CSV.parse(file_content, headers: true)

    raise InvalidHeadersError unless headers_valid?(csv)

    csv.each_with_object({}) do |row, values|
      content_id = row[WelshCsvService::CONTENT_ID_HEADER]
      next if content_id.nil?

      values[content_id] = row[WelshCsvService::WELSH_CONTENT_HEADER].to_s
    end
  end

private

  def headers_valid?(csv)
    HEADER_INDEXES.all? do |header, index|
      csv.headers[index] == header
    end
  end
end
