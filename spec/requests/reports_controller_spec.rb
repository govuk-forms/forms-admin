require "rails_helper"

RSpec.describe ReportsController, type: :request do
  let(:question_text) { "Question text" }
  let(:forms) { create_list(:form, 4, :live) }

  before do
    group = create :group
    forms.each { |form| group.group_forms.create!(form:) }
  end

  shared_examples "unauthorized user is forbidden" do
    context "when the user is not a super admin" do
      before do
        login_as_standard_user

        get path
      end

      it "returns http code 403 and renders forbidden" do
        expect(response).to have_http_status(:forbidden)
        expect(response).to render_template("errors/forbidden")
      end
    end
  end

  describe "#index" do
    let(:path) { reports_path }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns a success response and renders the index view" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("reports/index")
        expect(response.body).to include "Reports"
      end
    end
  end

  describe "#features" do
    let(:path) { report_features_path(tag: :live) }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200 and renders the features report view" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("reports/features")
        node = Capybara.string(response.body)
        expect(node).to have_xpath "//dl/div[1]/dt", text: "Total live forms"
        expect(node).to have_xpath "//dl/div[1]/dd", text: "4"
      end
    end

    context "when the tag is live-or-archived and CloudWatch data is available" do
      let(:path) { report_features_path(tag: "live-or-archived") }

      before do
        login_as_super_admin_user
        allow(Reports::TotalSubmissionsCloudWatchService).to receive(:new).and_return(
          instance_double(
            Reports::TotalSubmissionsCloudWatchService,
            submissions_data: { all_time: { total: 42_000 } },
          ),
        )
        get path
      end

      it "includes a total submissions row with the all-time total" do
        expect(response).to have_http_status(:ok)
        node = Capybara.string(response.body)
        expect(node).to have_text I18n.t("reports.features.features.total_submissions")
        expect(node).to have_text "42000"
      end
    end

    context "when the tag is live-or-archived and CloudWatch data is unavailable" do
      let(:path) { report_features_path(tag: "live-or-archived") }

      before do
        login_as_super_admin_user
        allow(Reports::TotalSubmissionsCloudWatchService).to receive(:new).and_return(
          instance_double(Reports::TotalSubmissionsCloudWatchService, submissions_data: nil),
        )
        get path
      end

      it "shows Data unavailable in the total submissions row" do
        node = Capybara.string(response.body)
        expect(node).to have_text I18n.t("reports.features.features.total_submissions")
        expect(node).to have_text I18n.t("reports.features.features.total_submissions_unavailable")
      end
    end

    context "when the tag is live" do
      let(:path) { report_features_path(tag: :live) }

      before do
        login_as_super_admin_user
        get path
      end

      it "does not include a total submissions row" do
        node = Capybara.string(response.body)
        expect(node).not_to have_text I18n.t("reports.features.features.total_submissions")
      end
    end
  end

  describe "#questions_with_answer_type" do
    let(:path) { report_questions_with_answer_type_path(tag: :live, answer_type: "email") }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      let(:form) do
        create(:form, :live, pages: [
          create(:page, answer_type: "email"),
        ])
      end
      let(:forms) { [form] }

      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200 with the expected report data" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("reports/questions_with_answer_type")
        node = Capybara.string(response.body)
        expect(node).to have_xpath "//thead/tr/th[3]", text: "Question text"
        expect(node).to have_xpath "//tbody/tr[1]/td[3]", text: form.pages.first.question_text
      end
    end
  end

  describe "#questions_with_add_another_answer" do
    let(:path) { report_questions_with_add_another_answer_path(tag: :live) }
    let(:form) do
      create(:form, :live, pages: [
        create(:page, is_repeatable: true),
      ])
    end
    let(:forms) { [form] }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("reports/feature_report")
        node = Capybara.string(response.body)
        expect(node).to have_xpath "//thead/tr/th[3]", text: "Question text"
        expect(node).to have_xpath "//tbody/tr/td[3]", text: form.pages.first.question_text
      end
    end
  end

  describe "#forms_that_are_copies" do
    let(:path) { report_forms_that_are_copies_path(tag: :live) }
    let(:original_form) { create(:form, :live) }
    let(:form) { create(:form, :live, copied_from_id: original_form.id) }
    let(:forms) { [form] }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the features report view" do
        expect(response).to render_template("reports/feature_report")
      end

      it "includes the report data" do
        node = Capybara.string(response.body)
        expect(node).to have_xpath "//thead/tr/th[1]", text: "Form name"
        expect(node).to have_xpath "//tbody/tr[1]/td[1]", text: form.name
      end
    end
  end

  describe "#forms_with_routes" do
    let(:path) { report_forms_with_routes_path(tag: :live) }
    let(:form) do
      form = create(:form, :live, :ready_for_routing)
      create(:condition, routing_page_id: form.pages.first.id, check_page_id: form.pages.first.id, answer_value: "Option 1", goto_page_id: form.pages.second.id)
      form.live_form_document.update!(content: form.reload.as_form_document(live_at: form.updated_at))
      form
    end
    let(:forms) { [form] }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200 with the expected report data" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("reports/feature_report")

        node = Capybara.string(response.body)
        expect(node).to have_xpath "//thead/tr/th[3]", text: "Number of routes"
        expect(node).to have_xpath "//tbody/tr[1]/td[3]", text: "1"
      end
    end
  end

  describe "#forms_with_branch_routes" do
    let(:path) { report_forms_with_branch_routes_path(tag: :live) }
    let(:form) do
      form = create(:form, :live, :ready_for_routing)
      create(:condition, routing_page_id: form.pages.first.id, check_page_id: form.pages.first.id, answer_value: "Option 1", goto_page_id: form.pages.third.id)
      create(:condition, routing_page_id: form.pages.second.id, check_page_id: form.pages.first.id, goto_page_id: form.pages.fourth.id)
      form.live_form_document.update!(content: form.reload.as_form_document(live_at: form.updated_at))
      form
    end
    let(:forms) { [form] }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200 with the expected report data" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("reports/feature_report")

        node = Capybara.string(response.body)
        expect(node).to have_xpath "//thead/tr/th[3]", text: "Number of routes"
        expect(node).to have_xpath "//tbody/tr/td[3]", text: "2"
        expect(node).to have_xpath "//thead/tr/th[4]", text: "Number of branch routes"
        expect(node).to have_xpath "//tbody/tr/td[4]", text: "1"
      end
    end
  end

  describe "#forms_with_payments" do
    let(:path) { report_forms_with_payments_path(tag: :live) }
    let(:form) { create(:form, :live, payment_url: "https://www.gov.uk/payments/organisation/service") }
    let(:forms) { [form] }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200 with the expected report data" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("reports/feature_report")

        node = Capybara.string(response.body)
        expect(node).to have_xpath "//thead/tr/th[1]", text: "Form name"
        expect(node).to have_xpath "//tbody/tr[1]/td[1]", text: form.name
      end
    end
  end

  describe "#forms_with_csv_submission_email_attachments" do
    let(:path) { report_forms_with_csv_submission_email_attachments_path(tag: :live) }
    let(:form) { create(:form, :live, submission_type: "email", submission_format: %w[csv]) }
    let(:forms) { [form] }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200 with the expected report data" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("reports/feature_report")

        node = Capybara.string(response.body)
        expect(node).to have_xpath "//thead/tr/th[1]", text: "Form name"
        expect(node).to have_xpath "//tbody/tr[1]/td[1]", text: form.name
      end
    end
  end

  describe "#forms_with_json_submission_email_attachments" do
    let(:path) { report_forms_with_json_submission_email_attachments_path(tag: :live) }
    let(:form) { create(:form, :live, submission_type: "email", submission_format: %w[json]) }
    let(:forms) { [form] }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200 with the expected report data" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("reports/feature_report")

        node = Capybara.string(response.body)
        expect(node).to have_xpath "//thead/tr/th[1]", text: "Form name"
        expect(node).to have_xpath "//tbody/tr[1]/td[1]", text: form.name
      end
    end
  end

  describe "#forms_with_daily_submission_csv" do
    let(:path) { report_forms_with_daily_submission_csv_path(tag: :live) }
    let(:form) { create(:form, :live, submission_type: "email", send_daily_submission_batch: true) }
    let(:forms) { [form] }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200 with the expected report data" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("reports/feature_report")

        node = Capybara.string(response.body)
        expect(node).to have_xpath "//thead/tr/th[1]", text: "Form name"
        expect(node).to have_xpath "//tbody/tr[1]/td[1]", text: form.name
      end
    end
  end

  describe "#forms_with_weekly_submission_csv" do
    let(:path) { report_forms_with_weekly_submission_csv_path(tag: :live) }
    let(:form) { create(:form, :live, submission_type: "email", send_weekly_submission_batch: true) }
    let(:forms) { [form] }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200 with the expected report data" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("reports/feature_report")

        node = Capybara.string(response.body)
        expect(node).to have_xpath "//thead/tr/th[1]", text: "Form name"
        expect(node).to have_xpath "//tbody/tr[1]/td[1]", text: form.name
      end
    end
  end

  describe "#forms_with_s3_submissions" do
    let(:path) { report_forms_with_s3_submissions_path(tag: :live) }
    let(:form) { create(:form, :live, submission_type: "s3", submission_format: %w[json]) }
    let(:forms) { [form] }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200 with the expected report data" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("reports/feature_report")

        node = Capybara.string(response.body)
        expect(node).to have_xpath "//thead/tr/th[1]", text: "Form name"
        expect(node).to have_xpath "//tbody/tr[1]/td[1]", text: form.name
      end
    end
  end

  describe "#forms_with_welsh_translation" do
    let(:path) { report_forms_with_welsh_translation_path(tag: :live) }
    let(:form) { create(:form, :live, welsh_completed: true) }
    let(:forms) { [form] }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200 with the expected report data" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("reports/feature_report")

        node = Capybara.string(response.body)
        expect(node).to have_xpath "//thead/tr/th[1]", text: "Form name"
        expect(node).to have_xpath "//tbody/tr[1]/td[1]", text: form.name
      end
    end
  end

  describe "#users" do
    let(:path) { report_users_path }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200 and renders the users report template" do
        expect(response).to have_http_status(:ok)

        expect(response).to render_template("reports/users")
      end
    end
  end

  describe "#add_another_answer" do
    let(:path) { report_add_another_answer_path }
    let(:report_data) do
      OpenStruct.new(
        count: 3,
        forms: [OpenStruct.new(form_id: 3, name: "form name", state: "Draft", repeatable_pages: [OpenStruct.new(page_id: 5, question_text:)])],
      )
    end

    before do
      add_another_answer_usage_service = Reports::AddAnotherAnswerUsageService.new
      allow(add_another_answer_usage_service).to receive(:add_another_answer_forms).and_return(report_data)
      allow(Reports::AddAnotherAnswerUsageService).to receive(:new).and_return(add_another_answer_usage_service)
    end

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200 and renders the add another answer template" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("reports/add_another_answer")

        expect(response.body).to include "All forms with add another answer"
        expect(response.body).to include question_text
      end
    end
  end

  describe "#last_signed_in_at" do
    let!(:users) do
      [
        create(:user, provider: :auth0, last_signed_in_at: (1.year + 2.months).ago),
        create(:user, provider: :auth0, last_signed_in_at: nil),
        create(:user, provider: :gds, last_signed_in_at: nil),
      ]
    end

    before do
      login_as_super_admin_user

      get report_last_signed_in_at_path
    end

    it "returns http code 200 and renders the last signed in at report" do
      expect(response).to have_http_status(:ok)
      expect(response).to render_template("reports/last_signed_in_at")

      expect(response.body).to include "When users last signed in"
      expect(response.body).to include users.first.email
      expect(response.body).to include users.second.email
      expect(response.body).to include users.third.email
    end
  end

  describe "selection question reports" do
    let(:page_with_autocomplete) { build(:page, :selection_with_autocomplete, question_text: "Autocomplete question") }
    let(:page_with_radios) { build(:page, :selection_with_radios, question_text: "Radios question") }
    let(:page_with_checkboxes) { build(:page, :selection_with_checkboxes, question_text: "Checkboxes question") }
    let(:form) { create(:form, :live, name: "A form", pages: [page_with_checkboxes, page_with_radios, page_with_autocomplete]) }
    let(:forms) { [form] }

    describe "#selection_questions_summary" do
      before do
        login_as_super_admin_user
        get report_selection_questions_summary_path(tag: :live)
      end

      it "returns http code 200 and renders the selection questions summary template" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("reports/selection_questions_summary")

        node = Capybara.string(response.body)
        expect(node).to have_xpath "(//dl)[1]/div[1]/dt", text: "Live forms with more than 30 options"
        expect(node).to have_xpath "(//dl)[1]/div[1]/dd", text: "1"
      end
    end

    describe "#selection_questions_with_autocomplete" do
      before do
        login_as_super_admin_user
        get report_selection_questions_with_autocomplete_path(tag: :live)
      end

      it "returns http code 200" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("reports/feature_report")

        expect(response.body).to include "A form"
        expect(response.body).to include "Autocomplete question"
      end
    end

    describe "#selection_questions_with_radios" do
      before do
        login_as_super_admin_user
        get report_selection_questions_with_radios_path(tag: :live)
      end

      it "returns http code 200 and renders the report" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("reports/feature_report")

        expect(response.body).to include "A form"
        expect(response.body).to include "Radios question"
      end
    end

    describe "#selection_questions_with_checkboxes" do
      before do
        login_as_super_admin_user
        get report_selection_questions_with_checkboxes_path(tag: :live)
      end

      it "returns http code 200 and renders the report" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("reports/feature_report")

        expect(response.body).to include "A form"
        expect(response.body).to include "Checkboxes question"
      end
    end
  end

  describe "#selection_questions_with_none_of_the_above" do
    let(:page) { build(:page, :with_selection_settings, question_text: "Question with none of the above", is_optional: true) }
    let(:form) { create(:form, :live, name: "A form", pages: [page]) }
    let(:forms) { [form] }

    before do
      login_as_super_admin_user
      get report_selection_questions_with_none_of_the_above_path(tag: :live)
    end

    it "returns http code 200 and renders the report" do
      expect(response).to have_http_status(:ok)
      expect(response).to render_template("reports/feature_report")

      expect(response.body).to include "A form"
      expect(response.body).to include "Question with none of the above"
      expect(response.body).to include "‘None of the above’ follow-up question"
    end
  end

  describe "csv downloads" do
    shared_examples_for "csv response" do
      it "returns http code 200 with content-type text/csv and expected filename" do
        expect(response).to have_http_status(:ok)
        expect(response.headers["content-type"]).to eq "text/csv; charset=iso-8859-1"
        expect(response.headers["content-disposition"]).to match("attachment; filename=#{expected_csv_filename}")
      end
    end

    describe "#live_forms_csv" do
      let(:forms) do
        live_forms = create_list(:form, 2, :live)
        archived_form = create(:form, :archived)
        [*live_forms, archived_form]
      end
      let(:expected_csv_filename) { "live_forms_report-2025-05-15 15:31:57 UTC.csv" }

      before do
        login_as_super_admin_user

        travel_to Time.utc(2025, 5, 15, 15, 31, 57)

        get report_live_forms_csv_path
      end

      it_behaves_like "csv response"

      it "has expected response body" do
        csv = CSV.parse(response.body, headers: true)
        expect(csv.headers).to eq Reports::FormsCsvReportService::FORM_CSV_HEADERS
        expect(csv.length).to eq 3
      end
    end

    describe "#forms_with_routes as csv" do
      let(:form) do
        form = create(:form, :live, :ready_for_routing)
        create(:condition, routing_page_id: form.pages.first.id, check_page_id: form.pages.first.id, answer_value: "Option 1", goto_page_id: form.pages.second.id)
        form.live_form_document.update!(content: form.reload.as_form_document(live_at: form.updated_at))
        form
      end
      let(:forms) { [form, *create_list(:form, 2, :live)] }
      let(:expected_csv_filename) { "live_forms_with_routes_report-2025-05-15 15:31:57 UTC.csv" }

      before do
        login_as_super_admin_user

        travel_to Time.utc(2025, 5, 15, 15, 31, 57)

        get report_forms_with_routes_path(tag: :live, format: :csv)
      end

      it_behaves_like "csv response"

      it "has expected response body" do
        csv = CSV.parse(response.body, headers: true)
        expect(csv.headers).to eq Reports::FormsCsvReportService::FORM_CSV_HEADERS
        expect(csv.length).to eq 1
        expect(csv.by_col["Form name"]).to eq [
          form.name,
        ]
      end
    end

    describe "#forms_with_payments as csv" do
      let(:form) { create(:form, :live, payment_url: "https://www.gov.uk/payments/organisation/service") }
      let(:forms) { [form, *create_list(:form, 2, :live)] }
      let(:expected_csv_filename) { "live_forms_with_payments_report-2025-05-15 15:31:57 UTC.csv" }

      before do
        login_as_super_admin_user

        travel_to Time.utc(2025, 5, 15, 15, 31, 57)

        get report_forms_with_payments_path(tag: :live, format: :csv)
      end

      it_behaves_like "csv response"

      it "has expected response body" do
        csv = CSV.parse(response.body, headers: true)
        expect(csv.headers).to eq Reports::FormsCsvReportService::FORM_CSV_HEADERS
        expect(csv.length).to eq 1
        expect(csv.by_col["Form name"]).to eq [
          form.name,
        ]
      end
    end

    describe "#forms_with_csv_submission_enabled as csv" do
      let(:form) { create(:form, :live, submission_type: "email", submission_format: %w[csv]) }
      let(:forms) { [form, *create_list(:form, 2, :live)] }
      let(:expected_csv_filename) { "live_forms_with_csv_submission_email_attachments_report-2025-05-15 15:31:57 UTC.csv" }

      before do
        login_as_super_admin_user

        travel_to Time.utc(2025, 5, 15, 15, 31, 57)

        get report_forms_with_csv_submission_email_attachments_path(tag: :live, format: :csv)
      end

      it_behaves_like "csv response"

      it "has expected response body" do
        csv = CSV.parse(response.body, headers: true)
        expect(csv.headers).to eq Reports::FormsCsvReportService::FORM_CSV_HEADERS
        expect(csv.length).to eq 1
        expect(csv.by_col["Form name"]).to eq [
          form.name,
        ]
      end
    end

    describe "#live_questions_csv" do
      let(:forms) do
        live_forms = create_list(:form, 2, :live, pages_count: 3)
        archived_form = create(:form, :archived, pages_count: 2)
        [*live_forms, archived_form]
      end
      let(:expected_csv_filename) { "live_questions_report-2025-05-15 15:31:57 UTC.csv" }

      before do
        login_as_super_admin_user

        travel_to Time.utc(2025, 5, 15, 15, 31, 57)

        get report_live_questions_csv_path
      end

      it_behaves_like "csv response"

      it "has expected response body" do
        csv = CSV.parse(response.body, headers: true)
        expect(csv.headers).to eq Reports::QuestionsCsvReportService::QUESTIONS_CSV_HEADERS
        expect(csv.length).to eq 8
      end
    end

    describe "#questions_with_answer_type as csv" do
      let(:form) do
        create(:form, :live, pages: [
          create(:page, answer_type: "text"),
        ])
      end
      let(:forms) { [form, *create_list(:form, 2, :live)] }
      let(:expected_csv_filename) { "live_questions_report_text_answer_type-2025-05-15 15:31:57 UTC.csv" }

      before do
        login_as_super_admin_user

        travel_to Time.utc(2025, 5, 15, 15, 31, 57)

        get report_questions_with_answer_type_path(tag: :live, answer_type: "text", format: :csv)
      end

      it_behaves_like "csv response"

      it "has expected response body" do
        csv = CSV.parse(response.body, headers: true)
        expect(csv.headers).to eq Reports::QuestionsCsvReportService::QUESTIONS_CSV_HEADERS
        expect(csv.length).to eq 1
      end
    end

    describe "#questions_with_add_another_answer as csv" do
      let(:form) do
        create(:form, :live, pages: [
          create(:page, is_repeatable: true),
        ])
      end
      let(:forms) { [form, *create_list(:form, 2, :live)] }
      let(:expected_csv_filename) { "live_questions_with_add_another_answer_report-2025-05-15 15:31:57 UTC.csv" }

      before do
        login_as_super_admin_user

        travel_to Time.utc(2025, 5, 15, 15, 31, 57)

        get report_questions_with_add_another_answer_path(tag: :live, format: :csv)
      end

      it_behaves_like "csv response"

      it "has expected response body" do
        csv = CSV.parse(response.body, headers: true)
        expect(csv.headers).to eq Reports::QuestionsCsvReportService::QUESTIONS_CSV_HEADERS
        expect(csv.length).to eq 1
      end
    end
  end

  describe "#contact_for_research" do
    let(:path) { report_contact_for_research_path }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200 and renders the template" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("reports/contact_for_research")
      end
    end
  end

  describe "#total_submissions" do
    let(:path) { report_total_submissions_path }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before { login_as_super_admin_user }

      context "when CloudWatch data is available" do
        let(:submissions_data) do
          {
            all_time: { total: 14_800 },
            year: {
              completed: { label: "2025", total: 12_000 },
              in_progress: { label: "2026", total: 2_800 },
            },
            month: {
              completed: { label: "March 2026", total: 1_200 },
              in_progress: { label: "April 2026", total: 300 },
            },
            week: {
              completed: { label: "14–20 Apr 2026", total: 310 },
              in_progress: { label: "21–27 Apr 2026", total: 42 },
            },
            day: {
              completed: { label: "22 Apr 2026", total: 85 },
              in_progress: { label: "23 Apr 2026", total: 12 },
            },
            weekly_breakdown: Array.new(52) { { label: "1–7 Apr 2026", total: 10 } },
            monthly_breakdown: Array.new(12) { { label: "March 2026", total: 100 } },
          }
        end

        before do
          allow(Reports::TotalSubmissionsCloudWatchService).to receive(:new).and_return(
            instance_double(Reports::TotalSubmissionsCloudWatchService, submissions_data:),
          )
          get path
        end

        it "returns 200 and renders the total_submissions template" do
          expect(response).to have_http_status(:ok)
          expect(response).to render_template("reports/total_submissions")
        end

        it "shows the all-time total" do
          expect(response.body).to include "14800"
        end

        it "shows the completed day label" do
          expect(response.body).to include "22 Apr 2026"
        end
      end

      context "when CloudWatch data is unavailable" do
        before do
          allow(Reports::TotalSubmissionsCloudWatchService).to receive(:new).and_return(
            instance_double(Reports::TotalSubmissionsCloudWatchService, submissions_data: nil),
          )
          get path
        end

        it "returns 200 and shows an error message" do
          expect(response).to have_http_status(:ok)
          expect(response).to render_template("reports/total_submissions")
          expect(response.body).to include I18n.t("reports.total_submissions.error_loading_data")
        end
      end
    end
  end
end
