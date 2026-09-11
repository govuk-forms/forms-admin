class WelshCsvImportService
  include WelshTranslationContentLabels

  class InvalidHeadersError < StandardError; end
  class InvalidEncodingError < StandardError; end

  class QuestionError < StandardError
    attr_reader :question_number

    def initialize(message, question_number)
      super(message)
      @question_number = question_number
    end
  end

  class DifferentNumberOfSelectionOptionsError < QuestionError; end
  class SelectionOptionsMismatchError < QuestionError; end
  class SelectionOptionTranslationsMissingError < QuestionError; end

  class MismatchWithCurrentFormError < StandardError
    attr_reader :row_number

    def initialize(message, row_number)
      super(message)
      @row_number = row_number
    end
  end

  class FormContentNotFoundError < MismatchWithCurrentFormError; end
  class QuestionTextMismatchError < MismatchWithCurrentFormError; end
  class ExitPageHeadingMismatchError < MismatchWithCurrentFormError; end

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
    raise InvalidEncodingError unless file_content.valid_encoding?

    file_content.delete_prefix!("\xEF\xBB\xBF") # delete UTF-8 BOM if present
    csv = CSV.parse(file_content, headers: true)

    raise InvalidHeadersError unless headers_valid?(csv)

    validate_selection_question_options!(csv)
    validate_matches_current_form!(csv)

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

  def validate_selection_question_options!(csv)
    current_form_rows_by_question = selection_option_rows_by_question(current_form_state_csv)

    selection_option_rows_by_question(csv).each do |question_number, selection_option_rows|
      current_form_rows = current_form_rows_by_question[question_number] || []

      if selection_option_rows.size != current_form_rows.size
        raise DifferentNumberOfSelectionOptionsError.new(
          "Number of selection options does not match the form", question_number
        )
      end

      if english_values(selection_option_rows) != english_values(current_form_rows)
        raise SelectionOptionsMismatchError.new("Selection options do not match the form", question_number)
      end

      welsh_values = welsh_values(selection_option_rows)
      # Raise if translations have been provided for some selection options, but not all
      next unless welsh_values.any?(&:present?) && welsh_values.any?(&:blank?)

      raise SelectionOptionTranslationsMissingError.new(
        "Selection options are missing translations", question_number
      )
    end
  end

  def validate_matches_current_form!(csv)
    # Check question text and exit page heading English content matches the current form,
    # to avoid applying translations to the wrong question or exit page if the order has changed.
    csv.each_with_index do |row, index|
      content_id = row[content_id_column]
      current_english = current_form_english_by_content_id[content_id]

      row_number = index + 2 # accounts for header row

      if current_english.nil?
        raise FormContentNotFoundError.new(
          "Content ID is not present for the current form: \"#{content_id}\"", row_number
        )
      end

      if is_question_text?(content_id) && row[english_column] != current_english
        raise QuestionTextMismatchError.new(
          "The question text does not have the same English content as the current form", row_number
        )
      end

      next unless is_exit_page_heading?(content_id) && row[english_column] != current_english

      raise ExitPageHeadingMismatchError.new(
        "The exit page heading does not have the same English content as the current form", row_number
      )
    end
  end

  def current_form_state_csv
    @current_form_state_csv ||= CSV.parse(WelshCsvService.new(@form).as_csv(include_bom: false), headers: true)
  end

  def current_form_english_by_content_id
    @current_form_english_by_content_id ||= current_form_state_csv.each_with_object({}) do |row, hash|
      hash[row[content_id_column]] = row[english_column]
    end
  end

  def selection_option_rows_by_question(csv)
    content_id_column = HEADER_INDEXES[WelshCsvService::CONTENT_ID_HEADER]
    csv.to_a
       .select { |row| is_selection_option?(row[content_id_column]) }
       .group_by { |row| question_number_from_label(row[content_id_column]) }
       .reject { |question_number, _| question_number.nil? }
  end

  def english_values(rows)
    rows.map { |row| row[english_column] }
  end

  def welsh_values(rows)
    rows.map { |row| row[welsh_column] }
  end

  def content_id_column
    HEADER_INDEXES[WelshCsvService::CONTENT_ID_HEADER]
  end

  def english_column
    HEADER_INDEXES[WelshCsvService::ENGLISH_CONTENT_HEADER]
  end

  def welsh_column
    HEADER_INDEXES[WelshCsvService::WELSH_CONTENT_HEADER]
  end
end
