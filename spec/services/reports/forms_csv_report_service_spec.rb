require "rails_helper"

RSpec.describe Reports::FormsCsvReportService do
  subject(:csv_reports_service) do
    described_class.new(form_documents)
  end

  let(:organisation_name) { Faker::Company.name }
  let(:organisation_id) { Faker::Number.number }
  let(:group_name) { Faker::Lorem.sentence }
  let(:group_external_id) { Faker::Alphanumeric.alphanumeric(number: 8) }
  let(:form_documents) do
    forms.map do |form|
      # FormDocumentsService adds in the organisation and group details as part of the database query
      form.latest_form_document.as_json
          .merge({
            "organisation_name" => organisation_name,
            "organisation_id" => organisation_id,
            "group_name" => group_name,
            "group_external_id" => group_external_id,
            "welsh_completed" => form.welsh_completed,
          })
    end
  end
  let(:form) do
    create(:form, :live,
           :with_support,
           :with_welsh_translation,
           payment_url: "https://www.gov.uk/payments/organisation/service",
           pages: [
             create(:page, :with_address_settings, is_repeatable: true),
             create(:page, :with_date_settings),
             create(:page, answer_type: "email"),
             create(:page, :with_full_name_settings),
             create(:page, answer_type: "national_insurance_number"),
             create(:page, answer_type: "number"),
             create(:page, answer_type: "phone_number"),
             create(:page, :with_selection_settings, is_optional: true),
             create(:page, :with_single_line_text_settings, is_repeatable: true),
           ],
           delivery_configurations: [
             create(:delivery_configuration, :immediate_email, formats: %w[csv json]),
             create(:delivery_configuration, :s3, formats: %w[csv]),
             create(:delivery_configuration, :daily_email),
             create(:delivery_configuration, :weekly_email),
           ])
  end
  let(:forms) { [form, create(:form, :live)] }

  describe "#csv" do
    it "returns a CSV with a header row and a row for each form" do
      csv = csv_reports_service.csv
      rows = CSV.parse(csv)
      expect(rows.length).to eq 3
    end

    it "has expected values" do
      csv = csv_reports_service.csv
      rows = CSV.parse(csv)
      expect(rows[1]).to contain_exactly(
        form.id.to_s,
        "live",
        form.name,
        form.form_slug,
        organisation_name,
        organisation_id.to_s,
        group_name,
        group_external_id,
        form.created_at.iso8601(6),
        form.first_made_live_at.iso8601(6),
        form_documents.first["content"]["live_at"],
        "1",
        "9",
        "false",
        "false",
        "false",
        "true",
        form.payment_url,
        form.support_url,
        form.support_url_text,
        form.support_email,
        form.support_phone,
        form.privacy_policy_url,
        form.what_happens_next_markdown,
        "email: csv, json\ns3: csv",
        "true",
        "true",
        "true",
        "false",
      )
    end
  end
end
