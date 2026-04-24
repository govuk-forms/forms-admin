require "rails_helper"

describe "reports/features.html.erb" do
  let(:report) do
    {
      total_forms: 3,
      copied_forms: 1,
      forms_with_answer_type: {
        address: 1,
        date: 1,
        email: 1,
        name: 1,
        national_insurance_number: 1,
        number: 1,
        organisation_name: 1,
        phone_number: 1,
        selection: 3,
        text: 3,
      }.with_indifferent_access,
      steps_with_answer_type: {
        address: 1,
        date: 1,
        email: 1,
        name: 1,
        national_insurance_number: 1,
        number: 1,
        organisation_name: 2,
        phone_number: 1,
        selection: 4,
        text: 5,
      }.with_indifferent_access,
      forms_with_payment: 1,
      forms_with_routing: 2,
      forms_with_add_another_answer: 3,
      forms_with_csv_submission_email_attachments: 2,
      forms_with_json_submission_email_attachments: 4,
      forms_with_s3_submissions: 5,
      forms_with_exit_pages: 1,
      forms_with_welsh_translation: 1,
    }
  end
  let(:tag) { "live" }
  let(:total_submissions) { nil }

  before do
    controller.request.path_parameters[:tag] = tag

    render template: "reports/features", locals: { tag:, data: report, total_submissions: }
  end

  describe "page title" do
    it "matches the heading" do
      expect(view.content_for(:title)).to eq "Feature and answer type usage in live forms"
    end
  end

  it "has a back link to the live form page" do
    expect(view.content_for(:back_link)).to have_link("Back to reports", href: reports_path)
  end

  it "contains page heading" do
    expect(rendered).to have_css("h1.govuk-heading-l", text: "Feature and answer type usage in live forms")
  end

  it "includes the number of total live forms" do
    expect(rendered).to have_css(".govuk-summary-list__row", text: "Total live forms#{report[:total_forms]}")
  end

  it "includes the number of copied live forms" do
    expect(rendered).to have_css(".govuk-summary-list__row", text: "Live forms that are copies#{report[:copied_forms]}")
  end

  it "has a table of answer type usage" do
    expect(rendered).to have_table "Answer type usage" do |table|
      expect(table.find_all("thead th").map(&:text)).to eq [
        "Answer type",
        "Number of live forms with this answer type",
        "Number of uses of this answer type in live forms",
      ]
    end
  end

  Page::ANSWER_TYPES.map(&:to_sym).each do |answer_type|
    it "contains a heading for #{answer_type}" do
      expect(rendered).to have_css("th", text: I18n.t("helpers.label.page.answer_type_options.names.#{answer_type}"))
    end

    it "includes the number of live forms with #{answer_type}" do
      expect(rendered).to have_css("[data-live-forms-with-answer-type-#{answer_type.to_s.dasherize}]", text: report[:forms_with_answer_type][answer_type].to_s)
    end

    it "includes the number of live pages with #{answer_type}" do
      expect(rendered).to have_css("[data-live-pages-with-answer-type-#{answer_type.to_s.dasherize}]", text: report[:steps_with_answer_type][answer_type].to_s)
    end
  end

  context "when an answer type is missing from the data" do
    let(:report) do
      {
        total_forms: 3,
        copied_forms: 0,
        forms_with_answer_type: { address: 1 },
        steps_with_answer_type: { address: 1 },
        forms_with_payment: 1,
        forms_with_routing: 2,
        forms_with_add_another_answer: 3,
        forms_with_csv_submission_email_attachments: 2,
      }
    end

    it "displays 0 for forms_with_answer_type" do
      expect(rendered).to have_css("[data-live-forms-with-answer-type-number]", text: "0")
    end

    it "displays 0 for steps_with_answer_type" do
      expect(rendered).to have_css("[data-live-pages-with-answer-type-number]", text: "0")
    end
  end

  it "includes the number of live forms with routes" do
    expect(rendered).to have_css(".govuk-summary-list__row", text: "Live forms with routes#{report[:forms_with_routing]}")
  end

  it "includes the number of live forms with payments" do
    expect(rendered).to have_css(".govuk-summary-list__row", text: "Live forms with payments#{report[:forms_with_payment]}")
  end

  it "includes the number of live forms with add another answer" do
    expect(rendered).to have_css(".govuk-summary-list__row", text: "Live forms with add another answer#{report[:forms_with_add_another_answer]}")
  end

  it "includes the number of live forms with CSV email attachments" do
    expect(rendered).to have_css(".govuk-summary-list__row", text: "Live forms with CSV email attachments#{report[:forms_with_csv_submission_email_attachments]}")
  end

  it "includes the number of live forms with JSON email attachments" do
    expect(rendered).to have_css(".govuk-summary-list__row", text: "Live forms with JSON email attachments#{report[:forms_with_json_submission_email_attachments]}")
  end

  it "includes the number of live forms with S3 submissions" do
    expect(rendered).to have_css(".govuk-summary-list__row", text: "Live forms with S3 submissions#{report[:forms_with_s3_submissions]}")
  end

  it "includes the number of live forms with exit pages" do
    expect(rendered).to have_css(".govuk-summary-list__row", text: "Live forms with exit pages#{report[:forms_with_exit_pages]}")
  end

  it "includes the number of live forms with a welsh translation" do
    expect(rendered).to have_css(".govuk-summary-list__row", text: "Live forms with Welsh translation#{report[:forms_with_welsh_translation]}")
  end

  it "has a link to the selection questions summary report" do
    expect(rendered).to have_link href: report_selection_questions_summary_path
  end
end
