require "rails_helper"

RSpec.describe Api::V3FormsController, type: :request do
  let(:headers) { { "ACCEPT": "application/json" } }

  describe "#index" do
    let(:schedule) { "daily" }
    let(:form_id) { form.id }

    before do
      # create some forms without the specified delivery schedule
      weekly_email_batch_form = create :form, :with_weekly_batch_email_delivery, :draft
      weekly_email_batch_form.save_draft!

      create :form, :with_email_delivery, :live_with_draft

      s3_delivery_form = create :form, :with_s3_delivery, :archived_with_draft
      s3_delivery_form.save_draft!
    end

    context "when there is a draft form with the specified delivery schedule" do
      let(:form) { create :form, :with_daily_batch_email_delivery, :draft }

      before do
        form.save_draft!

        get "/api/v3/forms?delivery_schedule=#{schedule}", headers:
      end

      it "returns an array containing only the form ID and state for the draft form" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq [{ form_id:, state: "draft" }].to_json
      end
    end

    context "when there is a live form with the specified delivery schedule" do
      let(:form) { create :form, :with_daily_batch_email_delivery, :live }

      before do
        form.delivery_configurations.first.delivery_schedule = "weekly"
        form.save_draft!

        get "/api/v3/forms?delivery_schedule=#{schedule}", headers:
      end

      it "returns an array containing only the form ID and state for the live form" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq [{ form_id:, state: "current" }].to_json
      end
    end

    context "when there is a live form and its draft with the specified delivery schedule" do
      let(:form) { create :form, :with_daily_batch_email_delivery, :live }

      before do
        form.save_draft!

        get "/api/v3/forms?delivery_schedule=#{schedule}", headers:
      end

      it "returns an array containing the form ID and state for the live and draft forms" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq [{ form_id:, state: "current" }, { form_id:, state: "draft" }].to_json
      end
    end

    context "when there is an archived form with the specified delivery schedule" do
      let(:form) { create :form, :with_daily_batch_email_delivery, :archived }

      before do
        form.delivery_configurations.first.delivery_schedule = "weekly"
        form.save_draft!

        get "/api/v3/forms?delivery_schedule=#{schedule}", headers:
      end

      it "returns an array containing only the form ID and state for the archived form" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq [{ form_id:, state: "current" }].to_json
      end
    end

    context "when there is an archived form and its draft with the specified delivery schedule" do
      let(:form) { create :form, :with_daily_batch_email_delivery, :archived }

      before do
        form.save_draft!

        get "/api/v3/forms?delivery_schedule=#{schedule}", headers:
      end

      it "returns an array containing the form ID and state for the archived and draft forms" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq [{ form_id:, state: "current" }, { form_id:, state: "draft" }].to_json
      end
    end

    context "when there is no form document with the specified delivery schedule" do
      let(:form) { create :form, :with_email_delivery, :archived }

      before do
        form.save_draft!

        get "/api/v3/forms?delivery_schedule=#{schedule}", headers:
      end

      it "returns an empty array" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq [].to_json
      end
    end

    context "when the schedule is not in the list of possible delivery schedules" do
      let(:schedule) { "fortnightly" }

      before do
        get "/api/v3/forms?delivery_schedule=#{schedule}", headers:
      end

      it "returns a 400 response" do
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to eq ""
      end
    end
  end
end
