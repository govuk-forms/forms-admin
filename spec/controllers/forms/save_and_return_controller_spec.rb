require "rails_helper"

RSpec.describe Forms::SaveAndReturnController, type: :request do
  let(:form) { create(:form, :live, save_and_return: save_and_return_original_value) }
  let(:save_and_return_original_value) { "disabled" }
  let(:current_user) { standard_user }
  let(:group) { create(:group, organisation: standard_user.organisation, save_and_return_enabled: true) }

  before do
    Membership.create!(group_id: group.id, user: standard_user, added_by: standard_user)
    GroupForm.create!(form_id: form.id, group_id: group.id)

    login_as current_user
  end

  describe "#new" do
    before do
      get save_and_return_path(form_id: form.id)
    end

    it "renders the save and return view" do
      expect(response).to have_rendered :new
    end

    it "uses the save and return input" do
      expect(assigns).to include save_and_return_input: an_instance_of(Forms::SaveAndReturnInput)
    end

    context "when the user is not authorized" do
      let(:current_user) { build :user }

      it "returns 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "#create" do
    let(:save_and_return) { "enabled" }
    let(:params) { { forms_save_and_return_input: { save_and_return: save_and_return } } }

    context "when the checkbox is checked" do
      let(:save_and_return) { "enabled" }

      it "updates the form save_and_return to 'enabled'" do
        expect {
          post(save_and_return_create_path(form_id: form.id), params:)
        }.to change { form.reload.save_and_return }.to("enabled")
      end

      it "redirects to the form overview page" do
        post(save_and_return_create_path(form_id: form.id), params:)
        expect(response).to redirect_to(form_path(form.id))
      end

      it "displays a success flash message" do
        post(save_and_return_create_path(form_id: form.id), params:)
        expect(flash[:success]).to eq(I18n.t("banner.success.form.save_and_return_enabled"))
      end
    end

    context "when the checkbox is not checked" do
      let(:save_and_return_original_value) { "enabled" }
      let(:save_and_return) { "disabled" }

      it "updates the form save_and_return flag to 'disabled'" do
        expect {
          post(save_and_return_create_path(form_id: form.id), params:)
        }.to change { form.reload.save_and_return }.to("disabled")
      end

      it "displays a success flash message" do
        post(save_and_return_create_path(form_id: form.id), params:)
        expect(flash[:success]).to eq(I18n.t("banner.success.form.save_and_return_disabled"))
      end
    end

    context "when the setting is unchanged" do
      let(:save_and_return_original_value) { "enabled" }
      let(:save_and_return) { "enabled" }

      it "does not display a flash message" do
        post(save_and_return_create_path(form_id: form.id), params:)
        expect(flash[:success]).to be_nil
      end
    end

    context "when the save_and_return value is invalid" do
      let(:save_and_return) { "invalid_value" }

      it "renders the new template with unprocessable content status" do
        post(save_and_return_create_path(form_id: form.id), params:)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to have_rendered :new
        expect(response.body).to include("Sorry, there was a problem. Please try again.")
      end
    end

    context "when the user is not authorized" do
      let(:current_user) { build :user }

      it "returns 403" do
        post(save_and_return_create_path(form_id: form.id), params:)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
