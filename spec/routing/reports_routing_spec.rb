require "rails_helper"

RSpec.describe ReportsController, type: :routing do
  describe "feature reports" do
    describe "routing" do
      %w[draft live].each do |tag|
        context "with #{tag} tag" do
          it "routes to #features for #{tag} forms" do
            expect(get: "/reports/features/#{tag}").to route_to("reports#features", tag:)
          end

          it "routes to #questions_with_answer_type for #{tag} forms" do
            expect(get: "/reports/features/#{tag}/questions-with-answer-type/text").to route_to("reports#questions_with_answer_type", tag:, answer_type: "text")
          end

          it "routes to #questions_with_add_another_answer for #{tag} forms" do
            expect(get: "/reports/features/#{tag}/questions-with-add-another-answer").to route_to("reports#questions_with_add_another_answer", tag:)
          end

          it "routes to #questions_with_add_another_answer for #{tag} forms with csv format" do
            expect(get: "/reports/features/#{tag}/questions-with-add-another-answer.csv").to route_to("reports#questions_with_add_another_answer", tag:, format: "csv")
          end

          it "routes to #forms_with_routes for #{tag} forms" do
            expect(get: "/reports/features/#{tag}/forms-with-routes").to route_to("reports#forms_with_routes", tag:)
          end

          it "routes to #forms_with_routes for #{tag} forms with csv format" do
            expect(get: "/reports/features/#{tag}/forms-with-routes.csv").to route_to("reports#forms_with_routes", tag:, format: "csv")
          end

          it "routes to #forms_with_payments for #{tag} forms" do
            expect(get: "/reports/features/#{tag}/forms-with-payments").to route_to("reports#forms_with_payments", tag:)
          end

          it "routes to #forms_with_payments for #{tag} forms with csv format" do
            expect(get: "/reports/features/#{tag}/forms-with-payments.csv").to route_to("reports#forms_with_payments", tag:, format: "csv")
          end

          it "routes to #forms_with_csv_submission_email_attachments for #{tag} forms" do
            expect(get: "/reports/features/#{tag}/forms-with-csv-submission-email-attachments").to route_to("reports#forms_with_csv_submission_email_attachments", tag:)
          end

          it "routes to #forms_with_csv_submission_email_attachments for #{tag} forms with csv format" do
            expect(get: "/reports/features/#{tag}/forms-with-csv-submission-email-attachments.csv").to route_to("reports#forms_with_csv_submission_email_attachments", tag:, format: "csv")
          end

          it "routes to #forms_with_json_submission_email_attachments for #{tag} forms" do
            expect(get: "/reports/features/#{tag}/forms-with-json-submission-email-attachments").to route_to("reports#forms_with_json_submission_email_attachments", tag:)
          end

          it "routes to #forms_with_json_submission_email_attachments for #{tag} forms with csv format" do
            expect(get: "/reports/features/#{tag}/forms-with-json-submission-email-attachments.csv").to route_to("reports#forms_with_json_submission_email_attachments", tag:, format: "csv")
          end

          it "routes to #forms_with_s3_submissions for #{tag} forms" do
            expect(get: "/reports/features/#{tag}/forms-with-s3-submissions").to route_to("reports#forms_with_s3_submissions", tag:)
          end

          it "routes to #forms_with_s3_submissions for #{tag} forms with csv format" do
            expect(get: "/reports/features/#{tag}/forms-with-s3-submissions.csv").to route_to("reports#forms_with_s3_submissions", tag:, format: "csv")
          end

          it "routes to #forms_with_branch_routes for #{tag} forms" do
            expect(get: "/reports/features/#{tag}/forms-with-branch-routes").to route_to("reports#forms_with_branch_routes", tag:)
          end

          it "routes to #forms_with_branch_routes for #{tag} forms with csv format" do
            expect(get: "/reports/features/#{tag}/forms-with-branch-routes.csv").to route_to("reports#forms_with_branch_routes", tag:, format: "csv")
          end

          it "routes to #forms_with_exit_pages for #{tag} forms" do
            expect(get: "/reports/features/#{tag}/forms-with-exit-pages").to route_to("reports#forms_with_exit_pages", tag:)
          end

          it "routes to #forms_with_exit_pages for #{tag} forms with csv format" do
            expect(get: "/reports/features/#{tag}/forms-with-exit-pages.csv").to route_to("reports#forms_with_exit_pages", tag:, format: "csv")
          end
        end
      end

      context "with invalid tag" do
        it "does not route to #features" do
          expect(get: "/reports/features/foo").not_to route_to("reports#features", tag: "foo")
        end

        it "does not route to #questions_with_answer_type" do
          expect(get: "/reports/features/bar/questions-with-answer-type/text").not_to route_to("reports#questions_with_answer_type", answer_type: "text", tag: "bar")
        end

        it "does not route to #questions_with_add_another_answer" do
          expect(get: "/reports/features/baz/questions-with-add-another-answer").not_to route_to("reports#questions_with_add_another_answer", tag: "baz")
        end

        it "does not route to #questions_with_add_another_answer with csv format" do
          expect(get: "/reports/features/qux/questions-with-add-another-answer.csv").not_to route_to("reports#questions_with_add_another_answer", format: "csv", tag: "qux")
        end

        it "does not route to #forms_with_routes" do
          expect(get: "/reports/features/thud/forms-with-routes").not_to route_to("reports#forms_with_routes", tag: "thud")
        end

        it "does not route to #forms_with_routes with csv format" do
          expect(get: "/reports/features/foo/forms-with-routes.csv").not_to route_to("reports#forms_with_routes", format: "csv", tag: "foo")
        end

        it "does not route to #forms_with_branch_routes" do
          expect(get: "/reports/features/foo/forms-with-branch-routes").not_to route_to("reports#forms_with_branch_routes", tag: "foo")
        end

        it "does not route to #forms_with_branch_routes with csv format" do
          expect(get: "/reports/features/foo/forms-with-branch-routes.csv").not_to route_to("reports#forms_with_branch_routes", tag: "foo", format: "csv")
        end

        it "does not route to #forms_with_payments" do
          expect(get: "/reports/features/bar/forms-with-payments").not_to route_to("reports#forms_with_payments", tag: "bar")
        end

        it "does not route to #forms_with_payments with csv format" do
          expect(get: "/reports/features/baz/forms-with-payments.csv").not_to route_to("reports#forms_with_payments", format: "csv", tag: "baz")
        end

        it "does not route to #forms_with_csv_submission_enabled" do
          expect(get: "/reports/features/qux/forms-with-csv-submission-enabled").not_to route_to("reports#forms_with_csv_submission_enabled", tag: "qux")
        end

        it "does not route to #forms_with_csv_submission_enabled with csv format" do
          expect(get: "/reports/features/thud/forms-with-csv-submission-enabled.csv").not_to route_to("reports#forms_with_csv_submission_enabled", format: "csv", tag: "thud")
        end
      end
    end
  end

  describe "total submissions report" do
    it "routes GET /reports/total-submissions to reports#total_submissions" do
      expect(get: "/reports/total-submissions").to route_to("reports#total_submissions")
    end
  end
end
