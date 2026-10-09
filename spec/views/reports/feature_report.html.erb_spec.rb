require "rails_helper"

describe "reports/feature_report" do
  let(:report) {}
  let(:records) { [] }
  let(:tag) { "live" }
  let(:form_document_tag) { tag }
  let(:type) { :forms }

  before do
    controller.request.path_parameters[:action] = report
    controller.request.path_parameters[:tag] = tag

    render locals: { tag:, report:, records:, type: }
  end

  context "with forms_with_csv_submission_email_attachments report" do
    let(:report) { "forms_with_csv_submission_email_attachments" }
    let(:records) do
      [
        { "form_id" => 1, "tag" => form_document_tag, "content" => { "name" => "All question types form" }, "organisation_name" => "Government Digital Service" },
        { "form_id" => 3, "tag" => form_document_tag, "content" => { "name" => "Branch route form" }, "organisation_name" => "Government Digital Service" },
      ]
    end

    describe "page title" do
      it "matches the heading" do
        expect(view.content_for(:title)).to eq "Live forms with CSV submission email attachments enabled"
        expect(rendered).to have_css "h1", text: view.content_for(:title)
      end
    end

    it "has a back link to feature usage report" do
      expect(view.content_for(:back_link)).to have_link("Back to feature and answer type usage", href: report_features_path)
    end

    it "has a link to download the CSV" do
      expect(rendered).to have_link("Download data about all live forms with CSV submission email attachments enabled (as a CSV)", href: report_forms_with_csv_submission_email_attachments_path(format: :csv))
    end

    describe "forms table" do
      it "has rows for each form" do
        expect(rendered).to have_table with_rows: [
          { "Form name" => "All question types form", "Organisation" => "Government Digital Service" },
          { "Form name" => "Branch route form", "Organisation" => "Government Digital Service" },
        ]
      end

      context "with live forms" do
        let(:tag) { "live" }

        it "has links for each form" do
          expect(rendered).to have_table do |table|
            expect(table).to have_link "All question types form", href: live_form_pages_path(1)
            expect(table).to have_link "Branch route form", href: live_form_pages_path(3)
          end
        end
      end

      context "with draft forms" do
        let(:tag) { "draft" }

        it "has links for each form" do
          expect(rendered).to have_table do |table|
            expect(table).to have_link "All question types form", href: form_pages_path(1)
            expect(table).to have_link "Branch route form", href: form_pages_path(3)
          end
        end
      end

      context "with archived forms" do
        let(:tag) { "live-or-archived" }
        let(:form_document_tag) { "archived" }

        it "has links for each form" do
          expect(rendered).to have_table do |table|
            expect(table).to have_link "All question types form", href: archived_form_pages_path(1)
            expect(table).to have_link "Branch route form", href: archived_form_pages_path(3)
          end
        end
      end
    end
  end

  context "with forms_with_payments report" do
    let(:report) { "forms_with_payments" }
    let(:records) do
      [
        { "form_id" => 1, "tag" => tag, "content" => { "name" => "All question types form" }, "organisation_name" => "Government Digital Service" },
        { "form_id" => 3, "tag" => tag, "content" => { "name" => "Branch route form" }, "organisation_name" => "Government Digital Service" },
      ]
    end

    describe "page title" do
      it "matches the heading" do
        expect(view.content_for(:title)).to eq "Live forms with payments"
        expect(rendered).to have_css "h1", text: view.content_for(:title)
      end
    end

    it "has a back link to feature usage report" do
      expect(view.content_for(:back_link)).to have_link("Back to feature and answer type usage", href: report_features_path)
    end

    it "has a link to download the CSV" do
      expect(rendered).to have_link("Download data about all live forms with payments as a CSV file", href: report_forms_with_payments_path(format: :csv))
    end

    describe "forms table" do
      it "has rows for each form" do
        expect(rendered).to have_table with_rows: [
          { "Form name" => "All question types form", "Organisation" => "Government Digital Service" },
          { "Form name" => "Branch route form", "Organisation" => "Government Digital Service" },
        ]
      end

      context "with live forms" do
        let(:tag) { "live" }

        it "has links for each form" do
          expect(rendered).to have_table do |table|
            expect(table).to have_link "All question types form", href: live_form_pages_path(1)
            expect(table).to have_link "Branch route form", href: live_form_pages_path(3)
          end
        end
      end

      context "with draft forms" do
        let(:tag) { "draft" }

        it "has links for each form" do
          expect(rendered).to have_table do |table|
            expect(table).to have_link "All question types form", href: form_pages_path(1)
            expect(table).to have_link "Branch route form", href: form_pages_path(3)
          end
        end
      end
    end
  end

  context "with forms_with_routes report" do
    let(:report) { "forms_with_routes" }
    let(:type) { :forms_with_routes }
    let(:records) do
      [
        { "form_id" => 1, "tag" => tag, "content" => { "name" => "All question types form" }, "organisation_name" => "Government Digital Service", "metadata" => { "number_of_questions" => { "with_routes" => 1 } } },
        { "form_id" => 3, "tag" => tag, "content" => { "name" => "Branch route form" }, "organisation_name" => "Government Digital Service", "metadata" => { "number_of_questions" => { "with_routes" => 2 } } },
      ]
    end

    describe "page title" do
      it "matches the heading" do
        expect(view.content_for(:title)).to eq "Live forms with routes"
        expect(rendered).to have_css "h1", text: view.content_for(:title)
      end
    end

    it "has a back link to feature usage report" do
      expect(view.content_for(:back_link)).to have_link("Back to feature and answer type usage", href: report_features_path)
    end

    it "has a link to download the CSV" do
      expect(rendered).to have_link("Download data about all live forms with routes as a CSV file", href: report_forms_with_routes_path(format: :csv))
    end

    describe "forms table" do
      it "has rows for each forms" do
        expect(rendered).to have_table with_rows: [
          { "Form name" => "All question types form", "Organisation" => "Government Digital Service", "Number of questions with routes" => "1" },
          { "Form name" => "Branch route form", "Organisation" => "Government Digital Service", "Number of questions with routes" => "2" },
        ]
      end

      context "with live forms" do
        let(:tag) { "live" }

        it "has links for each form" do
          expect(rendered).to have_table do |table|
            expect(table).to have_link "All question types form", href: live_form_pages_path(1)
            expect(table).to have_link "Branch route form", href: live_form_pages_path(3)
          end
        end
      end

      context "with draft forms" do
        let(:tag) { "draft" }

        it "has links for each form" do
          expect(rendered).to have_table do |table|
            expect(table).to have_link "All question types form", href: form_pages_path(1)
            expect(table).to have_link "Branch route form", href: form_pages_path(3)
          end
        end
      end
    end
  end

  context "with questions_with_add_another_answer report" do
    let(:report) { "questions_with_add_another_answer" }
    let(:type) { :questions }
    let(:records) do
      [
        { "type" => "question", "data" => { "question_text" => "Email address" }, "form" => { "form_id" => 1, "tag" => tag, "content" => { "name" => "All question types form" }, "organisation_name" => "Government Digital Service" } },
        { "type" => "question", "data" => { "question_text" => "What’s your email address?" }, "form" => { "form_id" => 3, "tag" => tag, "content" => { "name" => "Branch route form" }, "organisation_name" => "Government Digital Service" } },
      ]
    end

    describe "page title" do
      it "matches the heading" do
        expect(view.content_for(:title)).to eq "Questions with add another answer in live forms"
        expect(rendered).to have_css "h1", text: view.content_for(:title)
      end
    end

    it "has a back link to feature usage report" do
      expect(view.content_for(:back_link)).to have_link("Back to feature and answer type usage", href: report_features_path)
    end

    it "has a link to download the CSV" do
      expect(rendered).to have_link("Download all questions with add another answer in live forms as a CSV file", href: report_questions_with_add_another_answer_path(format: :csv))
    end

    describe "questions table" do
      it "has the correct headers" do
        page = Capybara.string(rendered.html)
        expect(page.find_all(".govuk-table__header")[0]).to have_text "Form name"
        expect(page.find_all(".govuk-table__header")[1]).to have_text "Organisation"
        expect(page.find_all(".govuk-table__header")[2]).to have_text "Question text"
      end

      it "has rows for each question" do
        expect(rendered).to have_table with_rows: [
          { "Form name" => "All question types form", "Organisation" => "Government Digital Service", "Question text" => "Email address" },
          { "Form name" => "Branch route form", "Organisation" => "Government Digital Service", "Question text" => "What’s your email address?" },
        ]
      end

      context "with live forms" do
        let(:tag) { "live" }

        it "has links for each form" do
          expect(rendered).to have_table do |table|
            expect(table).to have_link "All question types form", href: live_form_pages_path(1)
            expect(table).to have_link "Branch route form", href: live_form_pages_path(3)
          end
        end
      end

      context "with draft forms" do
        let(:tag) { "draft" }

        it "has links for each form" do
          expect(rendered).to have_table do |table|
            expect(table).to have_link "All question types form", href: form_pages_path(1)
            expect(table).to have_link "Branch route form", href: form_pages_path(3)
          end
        end
      end
    end
  end

  context "when type is selection_questions" do
    let(:type) { :selection_questions }

    it "has a back link to selection questions summary" do
      expect(view.content_for(:back_link)).to have_link(I18n.t("reports.back_to_selection_questions_summary"), href: report_selection_questions_summary_path)
    end
  end

  context "when type is selection_questions_with_none_of_the_above" do
    let(:type) { :selection_questions_with_none_of_the_above }

    it "has a back link to selection questions summary" do
      expect(view.content_for(:back_link)).to have_link(I18n.t("reports.back_to_selection_questions_summary"), href: report_selection_questions_summary_path)
    end
  end

  context "when there are no records to render" do
    let(:report) { "forms_with_csv_submission_email_attachments" }
    let(:records) { [] }
    let(:tag) { "live" }

    it "does not have a link to download a CSV" do
      expect(rendered).not_to have_link(href: url_for(format: :csv))
    end

    it "does not render a table" do
      expect(rendered).not_to have_table
    end

    it "renders the empty message" do
      expect(rendered).to include I18n.t("reports.#{report}.empty", tag:)
    end
  end
end
