require "rails_helper"

RSpec.describe Api::V3FormDocumentsController, type: :request do
  let(:headers) { { "ACCEPT": "application/json" } }

  describe "#show" do
    context "when the form exists" do
      let(:form) { create(:form, :live) }

      before do
        create :form_document, :live, form: form, version: 2, content: { name: "v2 form" }
        create :form_document, :live, form: form, version: 3, content: { name: "v3 form" }
      end

      it "returns the specified live form document" do
        get("/api/v3/forms/#{form.id}/versions/2", headers:)
        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include({
          version: 2,
          name: "v2 form",
        })
      end

      it "returns 404 when a non-existent version is requested" do
        get("/api/v3/forms/#{form.id}/versions/4", headers:)
        expect(response).to have_http_status(:not_found)
      end

      it "logs the returned form document version", :capture_logging do
        get("/api/v3/forms/#{form.id}/versions/3", headers:)
        expect(log_line["form_document_version"]).to eq 3
      end

      context "when the form has a Welsh translation" do
        let(:form) { create(:form, :live, :with_welsh_translation) }

        before do
          create :form_document, :live, form: form, version: 2, language: "cy", content: { name: "Welsh v2 form" }
        end

        it "returns the Welsh draft form document when the Welsh is requested for a version that has Welsh" do
          get("/api/v3/forms/#{form.id}/versions/2?language=cy", headers:)
          expect(response).to have_http_status(:success)
          expect(response.parsed_body).to include({
            version: 2,
            name: "Welsh v2 form",
          })
        end

        it "returns 404 when the Welsh is requested for a version that does not have Welsh" do
          get("/api/v3/forms/#{form.id}/versions/3?language=cy", headers:)
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the form does not have a Welsh translation" do
        it "returns 404 when the Welsh is requested" do
          get("/api/v3/forms/#{form.id}/versions/draft?language=cy", headers:)
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the version isn't a number" do
        it "returns http not found" do
          get("/api/v3/forms/#{form.id}/versions/not-a-number", headers:)
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when the form doesn't exist" do
      before do
        get "/api/v3/forms/non-existent/versions/draft", headers:
      end

      it "returns http not found" do
        expect(response).to have_http_status(:not_found)
        expect(response.headers["Content-Type"]).to eq("application/json; charset=utf-8")
      end
    end
  end

  describe "#draft" do
    context "when the form exists" do
      let(:draft_form_name) { "Draft form" }
      let(:form) { create(:form, :live_with_draft, pages_count: 2) }

      before do
        # change the form object so we can be sure we're returning the draft form document
        form.name = draft_form_name
        form.save!
      end

      it "returns the draft form document" do
        get("/api/v3/forms/#{form.id}/versions/draft", headers:)
        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include({
          version: nil,
          form_id: form.id.to_s,
          name: draft_form_name,
        })
      end

      context "when the form has a Welsh translation" do
        let(:form) { create(:form, :live_with_draft, :with_welsh_translation) }

        it "returns the Welsh draft form document when the Welsh is requested" do
          get("/api/v3/forms/#{form.id}/versions/draft?language=cy", headers:)
          expect(response).to have_http_status(:success)
          expect(response.parsed_body).to include({
            version: nil,
            form_id: form.id.to_s,
            name: start_with("Welsh"),
          })
        end
      end

      context "when the form does not have a Welsh translation" do
        it "returns 404 when the Welsh is requested" do
          get("/api/v3/forms/#{form.id}/versions/draft?language=cy", headers:)
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "#live" do
    context "when the form is live" do
      let(:form) { create(:form, :live) }

      before do
        form_document = create :form_document, :live, form: form, version: 2
        form.update!(latest_form_document: form_document)
      end

      it "returns the latest form document version number" do
        get("/api/v3/forms/#{form.id}/versions/live", headers:)
        expect(response.parsed_body).to include({ version: 2 })
      end
    end

    context "when the form is archived" do
      let(:form) { create(:form, :archived) }

      it "returns http gone" do
        get("/api/v3/forms/#{form.id}/versions/live", headers:)
        expect(response).to have_http_status(:gone)
      end
    end

    context "when the form is not live" do
      let(:form) { create(:form, :draft) }

      it "returns http not found" do
        get("/api/v3/forms/#{form.id}/versions/live", headers:)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when a form with the given ID does not exist" do
      it "returns http not found" do
        get("/api/v3/forms/non-existent/versions/live", headers:)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "#archived" do
    context "when the form is archived" do
      let(:form) { create(:form, :archived) }

      before do
        form_document = create :form_document, :archived, form: form, version: 2
        form.update!(latest_form_document: form_document)
      end

      it "returns the latest form document version number" do
        get("/api/v3/forms/#{form.id}/versions/archived", headers:)
        expect(response.parsed_body).to include({ version: 2 })
      end
    end

    context "when the form is live" do
      let(:form) { create(:form, :live) }

      it "returns http not found" do
        get("/api/v3/forms/#{form.id}/versions/archived", headers:)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when a form with the given ID does not exist" do
      it "returns http not found" do
        get("/api/v3/forms/non-existent/versions/archived", headers:)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "#delivery_configurations" do
    let(:draft_email_configuration) do
      { "formats" => %w[csv], "delivery_method" => "email", "delivery_schedule" => "immediate" }
    end
    let(:s3_keys) { %w[s3_bucket_name s3_bucket_aws_account_id s3_bucket_region] }

    def get_delivery_configurations(state)
      get "/api/v3/forms/#{form.id}/delivery-configurations/#{state}", headers:
    end

    # It's slightly artificial for a form with state `live` or `archived` to have a different delivery configuration
    # from its draft, but it allows us to test that the right form document is used
    def make_draft_form_document_differ
      form.draft_form_document.content["delivery_configurations"] = [draft_email_configuration]
      form.draft_form_document.content["submission_email"] = "draft@example.gov.uk"
      form.draft_form_document.save!
    end

    shared_examples "returns the draft email delivery configuration" do
      it "returns the draft delivery configuration with the draft submission email" do
        get_delivery_configurations("draft")

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq [
          draft_email_configuration.merge("submission_email" => "draft@example.gov.uk"),
        ]
      end
    end

    shared_examples "returns the current email delivery configuration" do
      it "returns the current delivery configuration with the current submission email" do
        get_delivery_configurations("current")

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq [
          {
            "formats" => [],
            "delivery_method" => "email",
            "delivery_schedule" => "immediate",
            "submission_email" => "current@example.gov.uk",
          },
        ]
      end
    end

    context "when the form is a draft" do
      let(:form) { create :form, submission_email: "draft@example.gov.uk" }

      before do
        form.delivery_configurations.create!(
          delivery_method: "email",
          delivery_schedule: "immediate",
          formats: %w[csv],
        )
        form.save_draft!
      end

      include_examples "returns the draft email delivery configuration"

      context "when requesting the current live or archived delivery configuration" do
        before do
          get_delivery_configurations("current")
        end

        it "returns http not found" do
          expect(response).to have_http_status(:not_found)
          expect(response.headers["Content-Type"]).to eq("application/json; charset=utf-8")
        end
      end
    end

    context "when the form is live" do
      let(:form) { create :form, :with_email_delivery, :live, submission_email: "current@example.gov.uk" }

      before { make_draft_form_document_differ }

      include_examples "returns the draft email delivery configuration"
      include_examples "returns the current email delivery configuration"
    end

    context "when the form is live_with_draft" do
      let(:form) { create :form, :with_email_delivery, :live_with_draft, submission_email: "current@example.gov.uk" }

      before do
        form.delivery_configurations.first.update!(formats: %w[csv])
        form.delivery_configurations.reload
        form.submission_email = "draft@example.gov.uk"
        form.save_draft!
      end

      include_examples "returns the draft email delivery configuration"
      include_examples "returns the current email delivery configuration"
    end

    context "when the form is archived" do
      let(:form) { create :form, :with_email_delivery, :archived, submission_email: "current@example.gov.uk" }

      before { make_draft_form_document_differ }

      include_examples "returns the draft email delivery configuration"
      include_examples "returns the current email delivery configuration"
    end

    context "when the form is archived_with_draft" do
      let(:form) { create :form, :with_email_delivery, :archived_with_draft, submission_email: "current@example.gov.uk" }

      before do
        form.delivery_configurations.first.update!(formats: %w[csv])
        form.delivery_configurations.reload
        form.submission_email = "draft@example.gov.uk"
        form.save_draft!
      end

      include_examples "returns the draft email delivery configuration"
      include_examples "returns the current email delivery configuration"
    end

    context "when the form has an s3 delivery configuration" do
      let(:form) { create :form, :with_s3_configuration, :with_s3_delivery, :live, submission_email: "current@example.gov.uk" }
      let(:expected_configuration) do
        {
          "formats" => %w[json],
          "delivery_method" => "s3",
          "delivery_schedule" => "immediate",
          "s3_bucket_name" => "test-bucket",
          "s3_bucket_aws_account_id" => "123456789012",
          "s3_bucket_region" => "eu-west-1",
        }
      end

      before do
        # The factory creates the draft form document before the delivery configuration is added
        form.draft_form_document.content["delivery_configurations"] = form.latest_form_document.content["delivery_configurations"]
        form.draft_form_document.content["s3_bucket_name"] = "draft-bucket"
        form.draft_form_document.save!
      end

      it "returns the draft s3 bucket details without the submission email" do
        get_delivery_configurations("draft")

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq [expected_configuration.merge("s3_bucket_name" => "draft-bucket")]
      end

      it "returns the current s3 bucket details without the submission email" do
        get_delivery_configurations("current")

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq [expected_configuration]
      end
    end

    context "when the form has both email and s3 immediate delivery configurations" do
      let(:form) { create :form, :with_s3_configuration, :with_email_delivery, :with_s3_delivery, :live, submission_email: "current@example.gov.uk" }

      it "adds only the relevant destination details to each configuration" do
        get_delivery_configurations("current")

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to contain_exactly(
          {
            "formats" => [],
            "delivery_method" => "email",
            "delivery_schedule" => "immediate",
            "submission_email" => "current@example.gov.uk",
          },
          {
            "formats" => %w[json],
            "delivery_method" => "s3",
            "delivery_schedule" => "immediate",
            "s3_bucket_name" => "test-bucket",
            "s3_bucket_aws_account_id" => "123456789012",
            "s3_bucket_region" => "eu-west-1",
          },
        )
      end
    end

    context "when the form has a batch email delivery configuration" do
      let(:form) { create :form, submission_email: "draft@example.gov.uk" }

      before do
        form.delivery_configurations.create!(delivery_method: "email", delivery_schedule: "daily", formats: %w[csv])
        form.save_draft!
      end

      it "includes the submission email" do
        get_delivery_configurations("draft")

        expect(response.parsed_body).to eq [
          {
            "formats" => %w[csv],
            "delivery_method" => "email",
            "delivery_schedule" => "daily",
            "submission_email" => "draft@example.gov.uk",
          },
        ]
      end
    end

    context "when the destination details are blank in the form document" do
      let(:form) { create :form, :with_email_delivery, :with_s3_delivery, submission_email: "" }

      before do
        form.save_draft!
      end

      it "returns null for the relevant keys" do
        get_delivery_configurations("draft")

        email_configuration = response.parsed_body.find { |configuration| configuration["delivery_method"] == "email" }
        s3_configuration = response.parsed_body.find { |configuration| configuration["delivery_method"] == "s3" }

        expect(email_configuration).to include("submission_email" => nil)
        expect(email_configuration.keys).not_to include(*s3_keys)
        expect(s3_configuration).to include(
          "s3_bucket_name" => nil,
          "s3_bucket_aws_account_id" => nil,
          "s3_bucket_region" => nil,
        )
        expect(s3_configuration.keys).not_to include("submission_email")
      end
    end
  end
end
