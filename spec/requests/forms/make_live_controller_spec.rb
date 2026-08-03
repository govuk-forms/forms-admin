require "rails_helper"

RSpec.describe Forms::MakeLiveController, type: :request do
  let(:user) { build :user, organisation: }
  let(:form) { create(:form, :ready_for_live) }
  let(:id) { form.id }

  let(:form_params) { nil }

  let(:organisation) { test_org }
  let(:group_role) { :group_admin }
  let(:group) { create(:group, organisation:, status: :active) }

  before do
    form.set_task_status_service(TaskStatusService.new(form:))
  end

  describe "#new" do
    before do
      Membership.create!(group_id: group.id, user:, added_by: user, role: group_role)
      GroupForm.create!(form_id: form.id, group_id: group.id)

      login_as user
    end

    it "returns 200" do
      get make_live_path(form_id: form.id)
      expect(response).to have_http_status(:ok)
    end

    context "when the form is being created for the first time" do
      it "renders make your form live" do
        get make_live_path(form_id: form.id)
        expect(response).to render_template("make_your_form_live")
      end
    end

    context "when editing a draft of an existing live form" do
      let(:form) { create(:form, :live) }

      it "renders make your changes live" do
        get make_live_path(form_id: form.id)
        expect(response).to render_template("make_your_changes_live")
      end
    end

    context "when editing a draft of an archived form" do
      let(:form) { create(:form, :archived_with_draft) }

      it "renders make your changes live" do
        get make_live_path(form_id: form.id)
        expect(response).to render_template("make_archived_draft_live")
      end
    end

    context "when current user is not a group admin" do
      let(:group_role) { :editor }

      it "is forbidden" do
        get make_live_path(form_id: form.id)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the form has an existing live welsh form document" do
      let(:form) do
        create(:form, :with_welsh_translation,
               support_email: "english@example.gov.uk",
               support_email_cy: "welsh@example.gov.uk",
               what_happens_next_markdown: "English what happens next",
               what_happens_next_markdown_cy: "Welsh what happens next",
               question_section_completed: true,
               declaration_section_completed: true,
               share_preview_completed: true,
               privacy_policy_url: "https://www.gov.uk/english-privacy",
               privacy_policy_url_cy: "https://www.gov.uk/welsh-privacy",
               welsh_completed: true,
               pages: [build(:page, question_text: "English question", question_text_cy: "Welsh question")])
      end

      before do
        # Create the en and cy live FormDocuments
        form.make_live!
      end

      context "and a complete welsh translations" do
        it "renders make your changes live" do
          get make_live_path(form_id: form.id)
          expect(response).to render_template("make_your_changes_live")
        end
      end

      context "and in progress welsh translations" do
        before do
          # Add a declaration in English only to the draft form
          form.update!(declaration_markdown: "English declaration", share_preview_completed: true)
        end

        it "renders make your changes to english live" do
          get make_live_path(form_id: form.id)
          expect(response).to render_template("make_your_changes_to_english_live")
        end
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

      it "makes the form live" do
        post(make_live_path(form_id: form.id), params: form_params)
        expect(form.reload.live?).to be true
      end

      it "renders the confirmation page" do
        post(make_live_path(form_id: form.id), params: form_params)
        expect(response).to render_template(:confirmation)
      end

      it "sends an email to the organisation admins" do
        post(make_live_path(form_id: form.id), params: form_params)
        expect(ActionMailer::Base.deliveries.count).to eq(1)

        template_id = Settings.govuk_notify.admin_alerts.new_draft_form_made_live_template_id
        expect(ActionMailer::Base.deliveries.last.govuk_notify_template).to eq(template_id)
      end

      context "and that form has not been made live before" do
        it "has the page title 'Your form is live'" do
          post(make_live_path(form_id: form.id), params: form_params)
          expect(response.body).to include "Your form is live"
        end

        it "creates a FormDocument" do
          expect {
            post(make_live_path(form_id: form.id), params: form_params)
          }.to change(FormDocument, :count).by(1)
        end

        it "sets the FormDocument's live_at time to be equal to the form's updated_at time" do
          post(make_live_path(form_id: form.id), params: form_params)
          expect(FormDocument.find_by(form_id: form.id, tag: "live")["content"]["live_at"]).to eq form.reload.updated_at.strftime("%Y-%m-%dT%H:%M:%S.%6NZ")
        end
      end

      context "and that form has already been made live before" do
        context "and does not have draft changes" do
          let(:form) { create(:form, :live) }

          it "has the page title 'Your changes are live'" do
            post(make_live_path(form_id: form.id), params: form_params)
            expect(response.body).to include "Your changes are live"
          end

          it "does not change the live form document" do
            expect {
              post(make_live_path(form_id: form.id), params: form_params)
            }.not_to(change { form.reload.live_form_document.updated_at })
          end

          it "does not send an email to the organisation admins" do
            post(make_live_path(form_id: form.id), params: form_params)
            expect(ActionMailer::Base.deliveries.count).to eq(0)
          end
        end

        context "and has draft changes" do
          let(:form) do
            form = create(:form, :live_with_draft)
            form.update!(name: "Form with changes")
            form
          end

          it "has the page title 'Your changes are live'" do
            post(make_live_path(form_id: form.id), params: form_params)
            expect(response.body).to include "Your changes are live"
          end

          it "updates the form document" do
            expect {
              post(make_live_path(form_id: form.id), params: form_params)
            }.to(change { form.reload.live_form_document.updated_at })
          end
        end
      end
    end

    context "when deciding not to make a form live" do
      let(:form_params) { { forms_make_live_input: { confirm: :no } } }

      before do
        post(make_live_path(form_id: form.id), params: form_params)
      end

      it "does not make the form live" do
        expect(form.reload.draft?).to be true
      end

      it "redirects you to the form page" do
        expect(response).to redirect_to(form_path(form.id))
      end

      it "does not send an email to the organisation admins" do
        post(make_live_path(form_id: form.id), params: form_params)
        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    context "when all tasks are not complete" do
      let(:form) { create(:form, :missing_pages) }
      let(:form_params) { { forms_make_live_input: { confirm: "yes", form: } } }

      before do
        post(make_live_path(form_id: form.id), params: form_params)
      end

      it "returns 422" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not make the form live" do
        expect(form.reload.draft?).to be true
      end

      it "re-renders the page with an error" do
        expect(response).to render_template("make_your_form_live")
        expect(response.body).to include("You cannot make your form live because you have not finished adding questions.")
      end
    end

    context "when current user is not a group admin" do
      let(:group_role) { :editor }

      it "is forbidden" do
        post(make_live_path(form_id: form.id), params: form_params)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
