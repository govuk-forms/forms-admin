require "rails_helper"

RSpec.describe Forms::SubmissionAttachmentsController, type: :request do
  let(:form) do
    create(:form, :live, delivery_configurations: [
      create(:delivery_configuration, :immediate_email, formats: original_submission_format),
    ])
  end
  let(:user) { standard_user }
  let(:original_submission_format) { [] }
  let(:group) { create(:group, organisation: user.organisation) }

  before do
    Membership.create!(group_id: group.id, user:, added_by: user, role: :group_admin)
    GroupForm.create!(form:, group_id: group.id)
    login_as user
  end

  describe "#new" do
    before do
      get submission_attachments_path(form_id: form.id)
    end

    it "renders the submission attachments view" do
      expect(response).to have_rendered :new
    end

    it "uses the form submission attachments input" do
      expect(assigns).to include submission_attachments_input: an_instance_of(Forms::SubmissionAttachmentsInput)
    end

    context "when the form does not have an immediate email delivery configuration" do
      let(:form) do
        create(:form, delivery_configurations: [
          create(:delivery_configuration, :s3),
          create(:delivery_configuration, :daily_email),
        ])
      end

      it "returns a 404 page" do
        expect(response).to redirect_to :error_404
      end
    end
  end

  describe "#create" do
    let(:params) { { forms_submission_attachments_input: { submission_format: } } }

    context "when params are valid" do
      let(:submission_format) { %w[csv json] }

      it "updates the submission format for the email delivery method" do
        expect {
          post(submission_attachments_path(form_id: form.id), params:)
        }.to change { form.reload.delivery_configurations.first.formats }.to(submission_format)
      end

      it "redirects you to the form overview page" do
        post(submission_attachments_path(form_id: form.id), params:)
        expect(response).to redirect_to(form_path(form.id))
      end

      context "when submission format has changed to 'csv'" do
        let(:submission_format) { %w[csv] }

        it "displays a success flash message" do
          post(submission_attachments_path(form_id: form.id), params:)
          expect(flash[:success]).to eq(I18n.t("banner.success.form.receive_csv_enabled"))
        end
      end

      context "when submission format has changed to 'json'" do
        let(:submission_format) { %w[json] }

        it "displays a success flash message" do
          post(submission_attachments_path(form_id: form.id), params:)
          expect(flash[:success]).to eq(I18n.t("banner.success.form.receive_json_enabled"))
        end
      end

      context "when submission format has changed to 'csv json'" do
        let(:submission_format) { %w[csv json] }

        it "displays a success flash message" do
          post(submission_attachments_path(form_id: form.id), params:)
          expect(flash[:success]).to eq(I18n.t("banner.success.form.receive_csv_and_json_enabled"))
        end
      end

      context "when submission format has changed to blank" do
        let(:original_submission_format) { %w[csv json] }
        let(:submission_format) { %w[] }

        it "displays a success flash message" do
          post(submission_attachments_path(form_id: form.id), params:)
          expect(flash[:success]).to eq(I18n.t("banner.success.form.receive_no_attachments"))
        end
      end

      context "when submission format has not changed" do
        let(:submission_format) { %w[] }

        it "does not display a flash message" do
          post(submission_attachments_path(form_id: form.id), params:)
          expect(flash[:success]).to be_nil
        end
      end
    end

    context "when params are invalid" do
      let(:submission_format) { %w[apple] }

      it "returns 422" do
        post(submission_attachments_path(form_id: form.id), params:)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not update the form" do
        expect {
          post(submission_attachments_path(form_id: form.id), params:)
        }.not_to(change { form.reload.delivery_configurations.first.formats })
      end

      it "re-renders the page with an error" do
        post(submission_attachments_path(form_id: form.id), params:)
        expect(response).to render_template("new")
        expect(response.body).to include(I18n.t("activemodel.errors.models.forms/submission_attachments_input.invalid_submission_format"))
      end
    end

    context "when the form does not have an immediate email delivery configuration" do
      let(:form) do
        create(:form, delivery_configurations: [
          create(:delivery_configuration, :s3),
          create(:delivery_configuration, :daily_email),
        ])
      end
      let(:submission_format) { %w[csv] }

      it "returns a 404 page" do
        post(submission_attachments_path(form_id: form.id), params:)
        expect(response).to redirect_to :error_404
      end
    end
  end
end
