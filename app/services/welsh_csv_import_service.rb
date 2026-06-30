class WelshCsvImportService
  class InvalidHeadersError < StandardError; end

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

  attr_reader :csv_data

  def initialize(csv_data)
    @csv_data = csv_data
  end

  def read
    rows = CSV.parse(csv_data, headers: true)
    raise InvalidHeadersError unless rows.headers.include?(ID_COLUMN) && rows.headers.include?(WELSH_CONTENT_COLUMN)

    rows.each_with_object({}) do |row, values|
      id = row[ID_COLUMN]
      next if id.nil?

      values[id] = row[WELSH_CONTENT_COLUMN].to_s
    end
  end
end
