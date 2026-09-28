require "csv"

class Reports::QuestionsCsvReportService
  include ReportHelper

  IS_REPEATABLE = "Is repeatable?".freeze
  QUESTIONS_CSV_HEADERS = [
    "Form ID",
    "Status",
    "Form name",
    "Organisation name",
    "Organisation ID",
    "Group name",
    "Group ID",
    "Question number in form",
    "Question text",
    "Answer type",
    "Hint text",
    "Page heading",
    "Guidance markdown",
    "Is optional?",
    IS_REPEATABLE,
    "Has routes?",
    "Has branch routes?",
    "Number of exit pages",
    "Answer settings - Input type",
    "Select from a list settings - Only one option?",
    "Select from a list settings - Number of options",
    "Select from a list settings - None of the above?",
    "Select from a list settings - None of the above follow-up question",
    "Name settings - Title needed?",
    "Raw answer settings",
  ].freeze

  IS_REPEATABLE_COLUMN_INDEX = QUESTIONS_CSV_HEADERS.find_index(IS_REPEATABLE)

  attr_reader :question_page_documents

  def initialize(question_page_documents)
    @question_page_documents = question_page_documents
  end

  def csv
    CSV.generate do |csv|
      csv << QUESTIONS_CSV_HEADERS

      question_page_documents.each do |question_page_document|
        csv << question_row(question_page_document)
      end
    end
  end

private

  def question_row(step)
    form = step["form"]
    form_id = form["form_id"]
    GroupForm.find_by_form_id(form_id)&.group

    [
      form_id,
      form["tag"],
      form["content"]["name"],
      form["organisation_name"],
      form["organisation_id"],
      form["group_name"],
      form["group_external_id"],
      step["position"],
      step["data"]["question_text"],
      step["data"]["answer_type"],
      step["data"]["hint_text"],
      step["data"]["page_heading"],
      step["data"]["guidance_markdown"],
      step["data"]["is_optional"],
      step["data"]["is_repeatable"],
      step["routing_conditions"].present?,
      Reports::FormDocumentsService.step_has_secondary_skip_route?(form, step),
      Reports::FormDocumentsService.count_step_exit_pages(step),
      step.dig("data", "answer_settings", "input_type"),
      step.dig("data", "answer_settings", "only_one_option").presence.try { |o| o.to_s == "true" },
      step.dig("data", "answer_settings", "selection_options")&.length,
      step["data"]["answer_type"] == "selection" ? step["data"]["is_optional"] : nil,
      step["data"]["answer_type"] == "selection" ? none_of_the_above_question_text(step) : nil,
      step.dig("data", "answer_settings", "title_needed"),
      step["data"]["answer_settings"].as_json,
    ]
  end
end
