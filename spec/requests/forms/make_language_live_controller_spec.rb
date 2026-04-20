require "rails_helper"

RSpec.describe Forms::MakeLanguageLiveController, type: :request do
  let(:user) { build :user, organisation: }
  let(:form) { create(:form, :ready_for_live) }
  let(:id) { form.id }
  let(:language) { "en" }

  let(:form_params) { nil }

  let(:organisation) { test_org }
  let(:group_role) { :group_admin }
  let(:group) { create(:group, organisation:, status: :active) }

  describe "#new" do
    before do
      Membership.create!(group_id: group.id, user:, added_by: user, role: group_role)
      GroupForm.create!(form_id: form.id, group_id: group.id)

      login_as user
    end

    it "renders make your form live" do
      get make_language_live_path(form_id: form.id, language:)
      expect(response).to render_template("make_language_live/new")
      expect(response).to have_http_status(:ok)
    end

    context "when editing a draft of an existing live form" do
      let(:form) { create(:form, :live) }

      it "redirects to the form task list" do
        get make_language_live_path(form_id: form.id, language:)
        expect(response).to redirect_to(form_path(form_id: form.id))
      end
    end

    context "when editing a draft of an archived form" do
      let(:form) { create(:form, :archived_with_draft) }

      it "redirects to the form task list" do
        get make_language_live_path(form_id: form.id, language:)
        expect(response).to redirect_to(form_path(form_id: form.id))
      end
    end

    context "when current user is not a group admin" do
      let(:group_role) { :editor }

      it "is forbidden" do
        get make_language_live_path(form_id: form.id, language:)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "#create" do
    before do
      Membership.create!(group_id: group.id, user:, added_by: user, role: group_role)
      GroupForm.create!(form_id: form.id, group_id: group.id)
      create(:organisation_admin_user, organisation:)

      login_as user
    end

    context "when making a form live" do
      let(:form_params) { { forms_make_live_input: { confirm: :yes, form: } } }

      context "when the language being made live is English" do
        let(:language) { "en" }

        context "and the form has not been made live before" do
          it "redirects to the confirmation page" do
            post(make_language_live_path(form_id: form.id, language:), params: form_params)
            expect(response).to redirect_to(make_language_live_show_confirmation_path(form_id: form.id, language:))
          end

          it "creates an English FormDocument and makes the form live" do
            expect {
              post(make_language_live_path(form_id: form.id, language:), params: form_params)
            }.to change { FormDocument.where(language:).count }.by(1)
            .and change { form.reload.state }.to("live")
          end

          it "sets the English FormDocument's live_at time to be equal to the form's updated_at time" do
            post(make_language_live_path(form_id: form.id, language:), params: form_params)
            expect(FormDocument.find_by(form_id: form.id, tag: "live", language:)["content"]["live_at"]).to eq form.reload.updated_at.strftime("%Y-%m-%dT%H:%M:%S.%6NZ")
          end

          it "sends an email to the organisation admins" do
            post(make_language_live_path(form_id: form.id, language:), params: form_params)
            expect(ActionMailer::Base.deliveries.count).to eq(1)

            template_id = Settings.govuk_notify.admin_alerts.new_draft_form_made_live_template_id
            expect(ActionMailer::Base.deliveries.last.govuk_notify_template).to eq(template_id)
          end
        end

        context "and the form already has a live English form document" do
          let(:form) { create(:form, :live) }

          it "redirects to the form task list" do
            get make_language_live_path(form_id: form.id, language:)
            expect(response).to redirect_to(form_path(form_id: form.id))
          end
        end

        context "and the form already has a live Welsh form document" do
          subject(:form) { create :form, :live, :with_welsh_translation }

          it "redirects to the form task list" do
            get make_language_live_path(form_id: form.id, language:)
            expect(response).to redirect_to(form_path(form_id: form.id))
          end
        end
      end

      context "when the language being made live is Welsh" do
        let(:language) { "cy" }

        context "and the form has not been made live before" do
          it "redirects to the form task list" do
            post(make_language_live_path(form_id: form.id, language:), params: form_params)
            expect(response).to redirect_to(form_path(form_id: form.id))
          end
        end

        context "and the form already has a live English form document" do
          before do
            post(make_language_live_path(form_id: form.id, language: "en"), params: form_params)
          end

          it "redirects to the confirmation page" do
            post(make_language_live_path(form_id: form.id, language:), params: form_params)
            expect(response).to redirect_to(make_language_live_show_confirmation_path(form_id: form.id, language:))
          end

          it "creates an English FormDocument and makes the form live" do
            expect {
              post(make_language_live_path(form_id: form.id, language:), params: form_params)
            }.to change { FormDocument.where(language:).count }.by(1)
          end

          it "sets the English FormDocument's live_at time to be equal to the form's updated_at time" do
            post(make_language_live_path(form_id: form.id, language:), params: form_params)
            expect(FormDocument.find_by(form_id: form.id, tag: "live", language:)["content"]["live_at"]).to eq form.reload.updated_at.strftime("%Y-%m-%dT%H:%M:%S.%6NZ")
          end
        end

        context "and the form already has a live Welsh form document" do
          subject(:form) { create :form, :live, :with_welsh_translation }

          it "redirects to the form task list" do
            post(make_language_live_path(form_id: form.id, language:), params: form_params)
            expect(response).to redirect_to(form_path(form_id: form.id))
          end
        end
      end
    end

    context "when deciding not to make a form live" do
      let(:form_params) { { forms_make_live_input: { confirm: :no } } }

      before do
        post(make_language_live_path(form_id: form.id, language:), params: form_params)
      end

      it "does not make the form live" do
        expect(form.reload.draft?).to be true
      end

      it "redirects you to the form page" do
        expect(response).to redirect_to(form_path(form.id))
      end

      it "does not send an email to the organisation admins" do
        post(make_language_live_path(form_id: form.id, language:), params: form_params)
        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    context "when all tasks are not complete" do
      let(:form) { create(:form, :missing_pages) }
      let(:form_params) { { forms_make_live_input: { confirm: "yes", form: } } }

      before do
        post(make_language_live_path(form_id: form.id, language:), params: form_params)
      end

      it "returns 422" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not make the form live" do
        expect(form.reload.draft?).to be true
      end

      it "re-renders the page with an error" do
        expect(response).to render_template("new")
        expect(response.body).to include("You cannot make your form live because you have not finished adding questions.")
      end
    end

    context "when current user is not a group admin" do
      let(:group_role) { :editor }

      it "is forbidden" do
        post(make_language_live_path(form_id: form.id, language:), params: form_params)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
