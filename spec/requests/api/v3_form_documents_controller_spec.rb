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
end
