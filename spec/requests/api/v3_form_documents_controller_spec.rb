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
    context "when the form is a draft" do
      let(:form) { create :form }

      before do
        form.delivery_configurations.create!(
          delivery_method: "email",
          delivery_schedule: "immediate",
          formats: %w[csv],
        )
        form.save_draft!
      end

      context "when requesting the draft delivery configuration" do
        before do
          get "/api/v3/forms/#{form.id}/delivery-configurations/draft", headers:
        end

        it "returns the draft delivery configuration" do
          expect(response.body).to eq "[{\"formats\":[\"csv\"],\"delivery_method\":\"email\",\"delivery_schedule\":\"immediate\"}]"
        end
      end

      context "when requesting the current live or archived delivery configuration" do
        before do
          get "/api/v3/forms/#{form.id}/delivery-configurations/current", headers:
        end

        it "returns http not found" do
          expect(response).to have_http_status(:not_found)
          expect(response.headers["Content-Type"]).to eq("application/json; charset=utf-8")
        end
      end
    end

    context "when the form is live" do
      let(:form) { create :form, :with_email_delivery, :live }

      before do
        # It's slightly artificial for a form with state `live` to have a different delivery configuration from its
        # draft, but it allows us to test that the right form document is returned
        form.draft_form_document.content["delivery_configurations"] = "[{\"formats\":[\"csv\"],\"delivery_method\":\"email\",\"delivery_schedule\":\"immediate\"}]"
        form.draft_form_document.save!
      end

      context "when requesting the draft delivery configuration" do
        before do
          get "/api/v3/forms/#{form.id}/delivery-configurations/draft", headers:
        end

        it "returns the draft delivery configuration" do
          expect(response.body).to eq "[{\"formats\":[\"csv\"],\"delivery_method\":\"email\",\"delivery_schedule\":\"immediate\"}]"
        end
      end

      context "when requesting the current live or archived delivery configuration" do
        before do
          get "/api/v3/forms/#{form.id}/delivery-configurations/current", headers:
        end

        it "returns the live delivery configuration" do
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq "[{\"formats\":[],\"delivery_method\":\"email\",\"delivery_schedule\":\"immediate\"}]"
        end
      end
    end

    context "when the form is live_with_draft" do
      let(:form) { create :form, :with_email_delivery, :live_with_draft }

      before do
        form.delivery_configurations.first.update!(formats: %w[csv])
        form.delivery_configurations.reload
        form.save_draft!
      end

      context "when requesting the draft delivery configuration" do
        before do
          get "/api/v3/forms/#{form.id}/delivery-configurations/draft", headers:
        end

        it "returns the draft delivery configuration" do
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq "[{\"formats\":[\"csv\"],\"delivery_method\":\"email\",\"delivery_schedule\":\"immediate\"}]"
        end
      end

      context "when requesting the current live or archived delivery configuration" do
        before do
          get "/api/v3/forms/#{form.id}/delivery-configurations/current", headers:
        end

        it "returns the live delivery configuration" do
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq "[{\"formats\":[],\"delivery_method\":\"email\",\"delivery_schedule\":\"immediate\"}]"
        end
      end
    end

    context "when the form is archived" do
      let(:form) { create :form, :with_email_delivery, :archived }

      before do
        # It's slightly artificial for a form with state `archived` to have a different delivery configuration from its
        # draft, but it allows us to test that the right form document is returned
        form.draft_form_document.content["delivery_configurations"] = "[{\"formats\":[\"csv\"],\"delivery_method\":\"email\",\"delivery_schedule\":\"immediate\"}]"
        form.draft_form_document.save!
      end

      context "when requesting the draft delivery configuration" do
        before do
          get "/api/v3/forms/#{form.id}/delivery-configurations/draft", headers:
        end

        it "returns the draft delivery configuration" do
          expect(response.body).to eq "[{\"formats\":[\"csv\"],\"delivery_method\":\"email\",\"delivery_schedule\":\"immediate\"}]"
        end
      end

      context "when requesting the current live or archived delivery configuration" do
        before do
          get "/api/v3/forms/#{form.id}/delivery-configurations/current", headers:
        end

        it "returns the archived delivery configuration" do
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq "[{\"formats\":[],\"delivery_method\":\"email\",\"delivery_schedule\":\"immediate\"}]"
        end
      end
    end

    context "when the form is archived_with_draft" do
      let(:form) { create :form, :with_email_delivery, :archived_with_draft }

      before do
        form.delivery_configurations.first.update!(formats: %w[csv])
        form.delivery_configurations.reload
        form.save_draft!
      end

      context "when requesting the draft delivery configuration" do
        before do
          get "/api/v3/forms/#{form.id}/delivery-configurations/draft", headers:
        end

        it "returns the draft delivery configuration" do
          expect(response.body).to eq "[{\"formats\":[\"csv\"],\"delivery_method\":\"email\",\"delivery_schedule\":\"immediate\"}]"
        end
      end

      context "when requesting the current live or archived delivery configuration" do
        before do
          get "/api/v3/forms/#{form.id}/delivery-configurations/current", headers:
        end

        it "returns the archived delivery configuration" do
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq "[{\"formats\":[],\"delivery_method\":\"email\",\"delivery_schedule\":\"immediate\"}]"
        end
      end
    end
  end
end
