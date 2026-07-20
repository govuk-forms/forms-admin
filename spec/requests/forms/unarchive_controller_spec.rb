require "rails_helper"

RSpec.describe Forms::UnarchiveController, type: :request do
  let(:user) { standard_user }

  let(:form) { create(:form, :archived) }

  let(:group) { create(:group, organisation: user.organisation, status: :active) }
  let(:form_params) { nil }

  describe "#new" do
    before do
      Membership.create!(group_id: group.id, user: standard_user, added_by: standard_user, role: :group_admin)
      GroupForm.create!(form_id: form.id, group_id: group.id)

      login_as user

      get unarchive_path(form_id: form.id)
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the confirmation page" do
      expect(response).to render_template("unarchive_form")
    end

    context "when current user does not belong to the forms group" do
      let(:user) { build :user, organisation: standard_user.organisation }

      it "is forbidden" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "#create" do
    before do
      Membership.create!(group_id: group.id, user: standard_user, added_by: standard_user, role: :group_admin)
      GroupForm.create!(form_id: form.id, group_id: group.id)
      create(:organisation_admin_user, organisation: standard_user.organisation)

      login_as user
    end

    context "when making a form live again" do
      let(:form_params) { { forms_make_live_input: { confirm: :yes, form: } } }

      it "makes form live" do
        expect {
          post(unarchive_create_path(form_id: form.id), params: form_params)
        }.to change { form.reload.state }.to("live")
      end

      it "renders the confirmation page" do
        post(unarchive_create_path(form_id: form.id), params: form_params)
        expect(response).to render_template("forms/make_live/confirmation")
      end

      it "has the page title 'Your form is live'" do
        post(unarchive_create_path(form_id: form.id), params: form_params)
        expect(response.body).to include "Your form is live"
      end

      it "sends an email to the organisation admins" do
        post(unarchive_create_path(form_id: form.id), params: form_params)
        expect(ActionMailer::Base.deliveries.count).to eq(1)

        template_id = Settings.govuk_notify.admin_alerts.archived_form_made_live_template_id
        expect(ActionMailer::Base.deliveries.last.govuk_notify_template).to eq(template_id)
      end
    end

    context "when deciding not to make a form live again" do
      let(:form_params) { { forms_make_live_input: { confirm: :no } } }

      it "does not make the form live" do
        expect {
          post(unarchive_create_path(form_id: form.id), params: form_params)
        }.not_to(change { form.reload.state })
      end

      it "redirects you to the archived form page" do
        post(unarchive_create_path(form_id: form.id), params: form_params)
        expect(response).to redirect_to(archived_form_path(form.id))
      end

      it "does not send an email to the organisation admins" do
        post(make_live_path(form_id: form.id), params: form_params)
        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    context "when no option is selected" do
      let(:form_params) { { forms_make_live_input: { confirm: :"" } } }

      it "returns 422" do
        post(unarchive_create_path(form_id: form.id), params: form_params)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not make the form live" do
        expect {
          post(unarchive_create_path(form_id: form.id), params: form_params)
        }.not_to(change { form.reload.state })
      end

      it "re-renders the page with an error" do
        post(unarchive_create_path(form_id: form.id), params: form_params)
        expect(response).to render_template("unarchive_form")
        expect(response.body).to include("You must choose an option")
      end

      it "does not send an email to the organisation admins" do
        post(make_live_path(form_id: form.id), params: form_params)
        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    context "when current user does not belong to the forms group" do
      let(:user) { build :user, organisation: standard_user.organisation }

      it "is forbidden" do
        post(unarchive_create_path(form_id: form.id), params: form_params)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
