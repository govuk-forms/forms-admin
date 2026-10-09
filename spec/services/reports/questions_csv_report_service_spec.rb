require "rails_helper"

RSpec.describe Reports::QuestionsCsvReportService do
  subject(:csv_reports_service) do
    described_class.new(question_page_documents)
  end

  let(:organisation_name) { Faker::Company.name }
  let(:organisation_id) { Faker::Number.number }
  let(:group_name) { Faker::Lorem.sentence }
  let(:group_external_id) { Faker::Alphanumeric.alphanumeric(number: 8) }

  let(:question_page_documents) { Reports::FeatureReportService.new(form_documents).questions }
  let(:form_documents) do
    forms.map do |form|
      # FormDocumentsService adds in the organisation and group details as part of the database query
      form.latest_form_document.as_json
          .merge({
            "organisation_name" => organisation_name,
            "organisation_id" => organisation_id,
            "group_name" => group_name,
            "group_external_id" => group_external_id,
          })
    end
  end
  let(:form_with_all_answer_types) do
    create(:form, :live, :with_support, payment_url: "https://www.gov.uk/payments/organisation/service", pages: [
      create(:page, :with_address_settings, is_repeatable: true),
      create(:page, :with_date_settings),
      create(:page, answer_type: "email"),
      create(:page, :with_full_name_settings),
      create(:page, answer_type: "national_insurance_number"),
      create(:page, answer_type: "number"),
      create(:page, answer_type: "phone_number"),
      create(:page, :selection_with_none_of_the_above_question, none_of_the_above_question_text: "A follow-up question", none_of_the_above_question_is_optional: "true"),
      create(:page, :with_single_line_text_settings, is_repeatable: true),
    ])
  end
  let(:basic_route_form) do
    form = create(:form, :live, :ready_for_routing)
    create(:condition, routing_page_id: form.pages.first.id, check_page_id: form.pages.first.id, answer_value: "Option 1", skip_to_end: true)
    form.latest_form_document.update!(content: form.reload.as_form_document(live_at: form.updated_at))
    form
  end
  let(:forms) { [form_with_all_answer_types, basic_route_form] }

  describe "#csv" do
    it "returns a CSV with a header row and a rows for each question" do
      csv = csv_reports_service.csv
      rows = CSV.parse(csv)
      expect(rows.length).to eq 15
    end

    it "has expected values for text question" do
      csv = csv_reports_service.csv
      rows = CSV.parse(csv, headers: true)
      text_question_row = rows.detect { |row| row["Question text"] == form_with_all_answer_types.pages.last.question_text }
      expect(text_question_row.to_h).to eq({
        "Form ID" => form_with_all_answer_types.id.to_s,
        "Status" => "live",
        "Form name" => form_with_all_answer_types.name,
        "Organisation name" => organisation_name,
        "Organisation ID" => organisation_id.to_s,
        "Group name" => group_name,
        "Group ID" => group_external_id,
        "Question number in form" => form_with_all_answer_types.pages.last.position.to_s,
        "Question text" => form_with_all_answer_types.pages.last.question_text,
        "Answer type" => "text",
        "Hint text" => nil,
        "Page heading" => nil,
        "Guidance markdown" => nil,
        "Is optional?" => "false",
        "Is repeatable?" => "true",
        "Has routes?" => "false",
        "Number of exit pages" => "0",
        "Number of routes to exit pages" => "0",
        "Number of unreachable exit pages" => "0",
        "Answer settings - Input type" => "single_line",
        "Select from a list settings - Only one option?" => nil,
        "Select from a list settings - Number of options" => nil,
        "Select from a list settings - None of the above?" => nil,
        "Select from a list settings - None of the above follow-up question" => nil,
        "Name settings - Title needed?" => nil,
        "Raw answer settings" => "{\"input_type\" => \"single_line\"}",
      })
    end

    it "has expected values for selection question" do
      csv = csv_reports_service.csv
      rows = CSV.parse(csv, headers: true)
      selection_question_row = rows.detect { |row| row["Question text"] == form_with_all_answer_types.pages[7].question_text }
      expect(selection_question_row.to_h).to match({
        "Form ID" => form_with_all_answer_types.id.to_s,
        "Status" => "live",
        "Form name" => form_with_all_answer_types.name,
        "Organisation name" => organisation_name,
        "Organisation ID" => organisation_id.to_s,
        "Group name" => group_name,
        "Group ID" => group_external_id,
        "Question number in form" => form_with_all_answer_types.pages[7].position.to_s,
        "Question text" => form_with_all_answer_types.pages[7].question_text,
        "Answer type" => "selection",
        "Hint text" => nil,
        "Page heading" => nil,
        "Guidance markdown" => nil,
        "Is optional?" => "true",
        "Is repeatable?" => "false",
        "Has routes?" => "false",
        "Number of exit pages" => "0",
        "Number of routes to exit pages" => "0",
        "Number of unreachable exit pages" => "0",
        "Answer settings - Input type" => nil,
        "Select from a list settings - Only one option?" => "true",
        "Select from a list settings - Number of options" => "2",
        "Select from a list settings - None of the above?" => "true",
        "Select from a list settings - None of the above follow-up question" => "A follow-up question (optional)",
        "Name settings - Title needed?" => nil,
        "Raw answer settings" => String,
      })
    end

    it "has expected values for name question" do
      csv = csv_reports_service.csv
      rows = CSV.parse(csv, headers: true)
      name_question_row = rows.detect { |row| row["Question text"] == form_with_all_answer_types.pages[3].question_text }
      expect(name_question_row.to_h).to eq({
        "Form ID" => form_with_all_answer_types.id.to_s,
        "Status" => "live",
        "Form name" => form_with_all_answer_types.name,
        "Organisation name" => organisation_name,
        "Organisation ID" => organisation_id.to_s,
        "Group name" => group_name,
        "Group ID" => group_external_id,
        "Question number in form" => form_with_all_answer_types.pages[3].position.to_s,
        "Question text" => form_with_all_answer_types.pages[3].question_text,
        "Answer type" => "name",
        "Hint text" => nil,
        "Page heading" => nil,
        "Guidance markdown" => nil,
        "Is optional?" => "false",
        "Is repeatable?" => "false",
        "Has routes?" => "false",
        "Number of exit pages" => "0",
        "Number of routes to exit pages" => "0",
        "Number of unreachable exit pages" => "0",
        "Answer settings - Input type" => "full_name",
        "Select from a list settings - Only one option?" => nil,
        "Select from a list settings - Number of options" => nil,
        "Select from a list settings - None of the above?" => nil,
        "Select from a list settings - None of the above follow-up question" => nil,
        "Name settings - Title needed?" => "false",
        "Raw answer settings" => "{\"input_type\" => \"full_name\", \"title_needed\" => false}",
      })
    end

    it "has expected values for question with routing conditions" do
      csv = csv_reports_service.csv
      rows = CSV.parse(csv, headers: true)
      routing_question_row = rows.detect { |row| row["Question text"] == basic_route_form.pages.first.question_text }
      expect(routing_question_row.to_h).to eq({
        "Form ID" => basic_route_form.id.to_s,
        "Status" => "live",
        "Form name" => basic_route_form.name,
        "Organisation name" => organisation_name,
        "Organisation ID" => organisation_id.to_s,
        "Group name" => group_name,
        "Group ID" => group_external_id,
        "Question number in form" => basic_route_form.pages.first.position.to_s,
        "Question text" => basic_route_form.pages.first.question_text,
        "Answer type" => "selection",
        "Hint text" => nil,
        "Page heading" => nil,
        "Guidance markdown" => nil,
        "Is optional?" => "false",
        "Is repeatable?" => "false",
        "Has routes?" => "true",
        "Number of exit pages" => "0",
        "Number of routes to exit pages" => "0",
        "Number of unreachable exit pages" => "0",
        "Answer settings - Input type" => nil,
        "Select from a list settings - Only one option?" => "true",
        "Select from a list settings - Number of options" => "2",
        "Select from a list settings - None of the above?" => "false",
        "Select from a list settings - None of the above follow-up question" => "No follow-up question",
        "Name settings - Title needed?" => nil,
        "Raw answer settings" => "{\"only_one_option\" => \"true\", \"selection_options\" => [{\"name\" => \"Option 1\", \"value\" => \"Option 1\"}, {\"name\" => \"Option 2\", \"value\" => \"Option 2\"}]}",
      })
    end
  end
end
