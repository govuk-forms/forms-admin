require "rails_helper"

RSpec.describe Api::FormDocumentsController, type: :request do
  let(:headers) { { "ACCEPT": "application/json" } }

  describe "#show" do
    context "when the form exists" do
      context "when the tag is draft" do
        let(:draft_form_name) { "Draft form" }
        let(:form) { create(:form, :live_with_draft, pages_count: 2) }

        before do
          # change the form object so we can be sure we're returning the draft form document
          form.name = draft_form_name
          form.save!

          get "/api/v2/forms/#{form.id}/draft", headers:
        end

        it "returns http success" do
          expect(response).to have_http_status(:success)
        end

        it "returns the draft form document" do
          expect(response.parsed_body).to include({
            form_id: form.id.to_s,
            name: draft_form_name,
          })
        end

        it "includes the form's steps in the response" do
          expect(response.parsed_body["steps"].count).to eq(2)
        end
      end

      context "when the tag is live" do
        let(:live_form_name) { "Live form" }
        let(:form) { create(:form, :live, name: live_form_name) }

        before do
          # change the form object so we can be sure we're returning the live form document
          form.name = "Draft form"
          form.save!

          get "/api/v2/forms/#{form.id}/live", headers:
        end

        it "returns http success" do
          expect(response).to have_http_status(:success)
        end

        it "returns the live form document" do
          expect(response.parsed_body).to include({
            form_id: form.id.to_s,
            name: live_form_name,
          })
        end
      end

      context "when the tag is archived" do
        let(:archived_form_name) { "Archived form" }
        let(:form) { create(:form, :archived, name: archived_form_name) }

        before do
          # change the form object so we can be sure we're returning the archived form document
          form.name = "Draft form"
          form.save!

          get "/api/v2/forms/#{form.id}/archived"
        end

        it "returns http success" do
          expect(response).to have_http_status(:success)
        end

        it "returns the archived form document" do
          expect(response.parsed_body).to include({
            form_id: form.id.to_s,
            name: archived_form_name,
          })
        end
      end
    end

    context "when the form doesn't exist" do
      before do
        get "/api/v2/forms/non-existent/draft", headers:
      end

      it "returns http not found" do
        expect(response).to have_http_status(:not_found)
        expect(response.headers["Content-Type"]).to eq("application/json; charset=utf-8")
      end
    end

    context "when a form document with the given tag doesn't exist" do
      let(:form) { create :form }

      before do
        get "/api/v2/forms/#{form.id}/live", headers:
      end

      it "returns http not found" do
        expect(response).to have_http_status(:not_found)
        expect(response.headers["Content-Type"]).to eq("application/json; charset=utf-8")
      end
    end

    context "when given an unsupported tag" do
      let(:form) { create :form }

      before do
        get "/api/v2/forms/#{form.id}/unknown-tag", headers:
      end

      it "returns http not found" do
        expect(response).to have_http_status(:not_found)
        expect(response.headers["Content-Type"]).to eq("application/json; charset=utf-8")
      end
    end

    describe "language param" do
      let(:form) { create :form }

      before do
        create :form_document, form: form, tag: "live", language: "en", content: { form_id: form.id.to_s, language: "en" }
        create :form_document, form: form, tag: "live", language: "cy", content: { form_id: form.id.to_s, language: "cy" }
      end

      it "when not given a language, defaults to english returns the live form document in english" do
        get("/api/v2/forms/#{form.id}/live", headers:)
        expect(response.parsed_body).to include({
          form_id: form.id.to_s,
          language: "en",
        })
      end

      it "when given welsh param returns the live form document in welsh" do
        get("/api/v2/forms/#{form.id}/live?language=cy", headers:)
        expect(response.parsed_body).to include({
          form_id: form.id.to_s,
          language: "cy",
        })
      end

      it "when given a language which doesn't exist returns http not found" do
        get("/api/v2/forms/#{form.id}/live?language=unknown-language", headers:)
        expect(response).to have_http_status(:not_found)
        expect(response.headers["Content-Type"]).to eq("application/json; charset=utf-8")
      end
    end
  end

  describe "#group" do
    context "when the form exists" do
      let(:form) { create(:form) }
      let(:group) { create(:group, organisation: test_org) }
      let(:group_admin) { create(:user, organisation: test_org) }

      before do
        organisation_admin_user
        create(:membership, user: group_admin, group:, role: :group_admin)
        create(:membership, user: create(:user, organisation: test_org), group:, role: :editor)

        group.group_forms.create!(form_id: form.id)
      end

      it "returns the group" do
        get("/api/v2/forms/#{form.id}/group", headers:)

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to eq({
          "external_id" => group.external_id,
          "name" => group.name,
          "group_admin_users" => [
            { "name" => group_admin.name, "email" => group_admin.email },
          ],
          "organisation" => {
            "id" => test_org.id,
            "name" => test_org.name,
            "organisation_admin_users" => [
              { "name" => organisation_admin_user.name, "email" => organisation_admin_user.email },
            ],
          },
        })
      end
    end

    context "when the form doesn't exist" do
      it "returns http not found" do
        get("/api/v2/forms/non-existent/group", headers:)

        expect(response).to have_http_status(:not_found)
        expect(response.headers["Content-Type"]).to eq("application/json; charset=utf-8")
      end
    end
  end

  describe "logging", :capture_logging do
    let(:trace_id) { "Root=1-63441c4a-abcdef012345678912345678" }
    let(:request_id) { "a-request-id" }
    let(:form_id) { "a-form-id" }
    let(:headers) do
      {
        "ACCEPT": "application/json",
        "HTTP_X_AMZN_TRACE_ID": trace_id,
        "X-Request-ID": request_id,
      }
    end

    before do
      get api_v2_form_document_path(form_id:, tag: "live"), headers:
    end

    it "includes the trace ID on log lines" do
      expect(log_line["trace_id"]).to eq(trace_id)
    end

    it "includes the request_id on log lines" do
      expect(log_line["request_id"]).to eq(request_id)
    end

    it "includes the request_host on log lines" do
      expect(log_line["request_host"]).to eq("www.example.com")
    end

    it "includes the form_id on log lines" do
      expect(log_line["form_id"]).to eq(form_id)
    end
  end
end
