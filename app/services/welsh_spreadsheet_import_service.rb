class WelshSpreadsheetImportService
  class InvalidHeadersError < StandardError; end
  class InvalidFileTypeError < StandardError; end

  FORM_FIELD_IDS = %w[
    name
    declaration_markdown
    what_happens_next_markdown
    payment_url
    privacy_policy_url
    support_email
    support_phone
    support_url
    support_url_text
  ].freeze

  ID_COLUMN = "Identifier (do not change)".freeze
  WELSH_CONTENT_COLUMN = "Welsh content".freeze

  attr_reader :file

  def initialize(file)
    @file = file
  end

  def read
    case @file.content_type
    when "text/csv"
      read_csv
    when "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      read_xlsx
    when "application/vnd.oasis.opendocument.spreadsheet"
      read_ods
    else
      raise InvalidFileTypeError
    end
  end

  def read_csv
    csv_data = file.read.force_encoding("UTF-8")
    rows = CSV.parse(csv_data, headers: true)
    raise InvalidHeadersError unless rows.headers.include?(ID_COLUMN) && rows.headers.include?(WELSH_CONTENT_COLUMN)

    rows.each_with_object({}) do |row, values|
      id = row[ID_COLUMN]
      next if id.nil?

      values[id] = row[WELSH_CONTENT_COLUMN].to_s
    end
  end

  def read_xlsx
    xlsx = Roo::Excelx.new(file.path)
    headers = xlsx.row(1).map(&:to_s)
    raise InvalidHeadersError unless headers[0] == ID_COLUMN && headers[3] == WELSH_CONTENT_COLUMN

    xlsx.each_row_streaming(offset: 1).with_object({}) do |row, values|
      id = row[0]&.value
      next if id.blank?

      values[id] = row[3]&.value.to_s
    end
  end

  def read_ods
    ods = Roo::OpenOffice.new(file.path)
    rows = ods.sheet(0).parse(headers: true)
    raise InvalidHeadersError unless rows[0].include?(ID_COLUMN) && rows[0].include?(WELSH_CONTENT_COLUMN)

    rows.drop(1).each_with_object({}) do |row, values|
      id = row[ID_COLUMN]
      next if id.nil?

      values[id] = row[WELSH_CONTENT_COLUMN].to_s
    end
  end
end
