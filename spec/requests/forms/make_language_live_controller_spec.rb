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

      it "redirects to the make_changes_live view" do
        pending "not yet implemented"
        raise
      end
    end

    context "when editing a draft of an archived form" do
      let(:form) { create(:form, :archived_with_draft) }

      it "redirects to the make_changes_live view" do
        pending "not yet implemented"
        raise
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

      it "makes the form live" do
        pending "not yet implemented"
        raise
      end

      it "redirects to the confirmation page" do
        post(make_language_live_path(form_id: form.id, language:), params: form_params)
        expect(response).to redirect_to(make_language_live_show_confirmation_path(form_id: form.id, language:))
      end

      it "sends an email to the organisation admins" do
        pending "not yet implemented"
        raise
      end

      context "and that form has not been made live before" do
        it "redirects to the confirmation page" do
          post(make_language_live_path(form_id: form.id, language:), params: form_params)
          expect(response).to redirect_to(make_language_live_show_confirmation_path(form_id: form.id, language:))
        end

        it "creates a FormDocument" do
          pending "not yet implemented"
          raise
        end

        it "sets the FormDocument's live_at time to be equal to the form's updated_at time" do
          pending "not yet implemented"
          raise
        end
      end

      context "and that form has already been made live before" do
        it "redirects to the make_changes_live view" do
          pending "not yet implemented"
          raise
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
