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
      form.live_form_document.as_json
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
  let(:branch_route_form) do
    form = create(:form, :live, :ready_for_routing)
    create(:condition, :with_exit_page, routing_page_id: form.pages[0].id, check_page_id: form.pages[0].id, answer_value: "Option 1")
    create(:condition, routing_page_id: form.pages[1].id, check_page_id: form.pages[1].id, answer_value: "Option 1", goto_page_id: form.pages[3].id)
    create(:condition, routing_page_id: form.pages[2].id, check_page_id: form.pages[1].id, goto_page_id: form.pages[4].id)
    form.live_form_document.update!(content: form.reload.as_form_document(live_at: form.updated_at))
    form
  end
  let(:basic_route_form) do
    form = create(:form, :live, :ready_for_routing)
    create(:condition, routing_page_id: form.pages.first.id, check_page_id: form.pages.first.id, answer_value: "Option 1", skip_to_end: true)
    form.live_form_document.update!(content: form.reload.as_form_document(live_at: form.updated_at))
    form
  end
  let(:forms) { [form_with_all_answer_types, branch_route_form, basic_route_form] }

  describe "#csv" do
    it "returns a CSV with a header row and a rows for each question" do
      csv = csv_reports_service.csv
      rows = CSV.parse(csv)
      expect(rows.length).to eq 20
    end

    it "has expected values for text question" do
      csv = csv_reports_service.csv
      rows = CSV.parse(csv)
      text_question_row = rows.detect { |row| row.include? form_with_all_answer_types.pages.last.question_text }
      expect(text_question_row).to contain_exactly(
        form_with_all_answer_types.id.to_s,
        "live",
        form_with_all_answer_types.name,
        organisation_name,
        organisation_id.to_s,
        group_name,
        group_external_id,
        form_with_all_answer_types.pages.last.position.to_s,
        form_with_all_answer_types.pages.last.question_text,
        "text",
        nil,
        nil,
        nil,
        "false",
        "true",
        "false",
        "false",
        "single_line",
        nil,
        nil,
        nil,
        nil,
        nil,
        "{\"input_type\" => \"single_line\"}",
      )
    end

    it "has expected values for selection question" do
      csv = csv_reports_service.csv
      rows = CSV.parse(csv)
      selection_question_row = rows.detect { |row| row.include? form_with_all_answer_types.pages[7].question_text }
      expect(selection_question_row).to contain_exactly(
        form_with_all_answer_types.id.to_s,
        "live",
        form_with_all_answer_types.name,
        organisation_name,
        organisation_id.to_s,
        group_name,
        group_external_id,
        form_with_all_answer_types.pages[7].position.to_s,
        form_with_all_answer_types.pages[7].question_text,
        "selection",
        nil,
        nil,
        nil,
        "true",
        "false",
        "false",
        "false",
        nil,
        "true",
        "2",
        "true",
        "A follow-up question (optional)",
        nil,
        String,
      )
    end

    it "has expected values for name question" do
      csv = csv_reports_service.csv
      rows = CSV.parse(csv)
      name_question_row = rows.detect { |row| row.include? form_with_all_answer_types.pages[3].question_text }
      expect(name_question_row).to contain_exactly(
        form_with_all_answer_types.id.to_s,
        "live",
        form_with_all_answer_types.name,
        organisation_name,
        organisation_id.to_s,
        group_name,
        group_external_id,
        form_with_all_answer_types.pages[3].position.to_s,
        form_with_all_answer_types.pages[3].question_text,
        "name",
        nil,
        nil,
        nil,
        "false",
        "false",
        "false",
        "false",
        "full_name",
        nil,
        nil,
        nil,
        nil,
        "false",
        "{\"input_type\" => \"full_name\", \"title_needed\" => false}",
      )
    end

    it "has expected values for question with routing conditions" do
      csv = csv_reports_service.csv
      rows = CSV.parse(csv)
      routing_question_row = rows.detect { |row| row.include? basic_route_form.pages.first.question_text }
      expect(routing_question_row).to contain_exactly(
        basic_route_form.id.to_s,
        "live",
        basic_route_form.name,
        organisation_name,
        organisation_id.to_s,
        group_name,
        group_external_id,
        basic_route_form.pages.first.position.to_s,
        basic_route_form.pages.first.question_text,
        "selection",
        nil,
        nil,
        nil,
        "false",
        "false",
        "true",
        "false",
        nil,
        "true",
        "2",
        "false",
        "No follow-up question",
        nil,
        "{\"only_one_option\" => \"true\", \"selection_options\" => [{\"name\" => \"Option 1\", \"value\" => \"Option 1\"}, {\"name\" => \"Option 2\", \"value\" => \"Option 2\"}]}",
      )
    end

    it "has expected values for question with branch routing conditions" do
      csv = csv_reports_service.csv
      rows = CSV.parse(csv)
      routing_question_row = rows.detect { |row| row.include? branch_route_form.pages[1].question_text }
      expect(routing_question_row).to contain_exactly(
        branch_route_form.id.to_s,
        "live",
        branch_route_form.name.to_s,
        organisation_name,
        organisation_id.to_s,
        group_name,
        group_external_id,
        branch_route_form.pages[1].position.to_s,
        branch_route_form.pages[1].question_text,
        "selection",
        nil,
        nil,
        nil,
        "false",
        "false",
        "true",
        "true",
        nil,
        "true",
        "2",
        "false",
        "No follow-up question",
        nil,
        "{\"only_one_option\" => \"true\", \"selection_options\" => [{\"name\" => \"Option 1\", \"value\" => \"Option 1\"}, {\"name\" => \"Option 2\", \"value\" => \"Option 2\"}]}",
      )
    end
  end
end
