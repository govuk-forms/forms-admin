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
      rows = CSV.parse(csv, headers: true)
      expect(rows.first.to_h).to eq({
        "Form ID" => form.id.to_s,
        "Status" => "live",
        "Form name" => form.name,
        "Slug" => form.form_slug,
        "Organisation name" => organisation_name,
        "Organisation ID" => organisation_id.to_s,
        "Group name" => group_name,
        "Group ID" => group_external_id,
        "Created" => form.created_at.iso8601(6),
        "First made live" => form.first_made_live_at.iso8601(6),
        "Last made live" => form_documents.first["content"]["live_at"],
        "Version" => "1",
        "Number of questions" => "9",
        "Has routes" => "false",
        "Has exit pages" => "false",
        "Has question with multiple exit pages" => "false",
        "Has question with multiple routes to exit pages" => "false",
        "Number of exit pages" => "0",
        "Has add another answer" => "true",
        "Payment URL" => form.payment_url,
        "Support URL" => form.support_url,
        "Support URL text" => form.support_url_text,
        "Support email" => form.support_email,
        "Support phone" => form.support_phone,
        "Privacy policy URL" => form.privacy_policy_url,
        "What happens next markdown" => form.what_happens_next_markdown,
        "Delivery methods" => "email: csv, json\ns3: csv",
        "Daily submissions CSV enabled" => "true",
        "Weekly submissions CSV enabled" => "true",
        "Has Welsh translation" => "true",
        "Copy of answers enabled" => "false",
      })
    end
  end
end
