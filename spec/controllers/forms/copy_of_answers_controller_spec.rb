require "rails_helper"

RSpec.describe Forms::CopyOfAnswersController, type: :request do
  let(:form) { create(:form, :live, send_copy_of_answers: send_copy_of_answers_original_value) }
  let(:send_copy_of_answers_original_value) { "disabled" }
  let(:current_user) { standard_user }
  let(:group) { create(:group, organisation: standard_user.organisation) }

  before do
    Membership.create!(group_id: group.id, user: standard_user, added_by: standard_user)
    GroupForm.create!(form_id: form.id, group_id: group.id)

    login_as current_user
  end

  describe "#new" do
    before do
      get copy_of_answers_path(form_id: form.id)
    end

    it "renders the copy of answers view" do
      expect(response).to have_rendered :new
    end

    it "uses the copy of answers input" do
      expect(assigns).to include copy_of_answers_input: an_instance_of(Forms::CopyOfAnswersInput)
    end

    context "when the user is not authorized" do
      let(:current_user) { build :user }

      it "returns 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "#create" do
    let(:send_copy_of_answers) { "enabled" }
    let(:params) { { forms_copy_of_answers_input: { send_copy_of_answers: send_copy_of_answers } } }

    context "when the checkbox is checked" do
      let(:send_copy_of_answers) { "enabled" }

      it "updates the form send_copy_of_answers to 'enabled'" do
        expect {
          post(copy_of_answers_create_path(form_id: form.id), params:)
        }.to change { form.reload.send_copy_of_answers }.to("enabled")
      end

      it "redirects to the form overview page" do
        post(copy_of_answers_create_path(form_id: form.id), params:)
        expect(response).to redirect_to(form_path(form.id))
      end

      it "displays a success flash message" do
        post(copy_of_answers_create_path(form_id: form.id), params:)
        expect(flash[:success]).to eq(I18n.t("banner.success.form.copy_of_answers_enabled"))
      end
    end

    context "when the checkbox is not checked" do
      let(:send_copy_of_answers_original_value) { "enabled" }
      let(:send_copy_of_answers) { "disabled" }

      it "updates the form send_copy_of_answers flag to 'disabled'" do
        expect {
          post(copy_of_answers_create_path(form_id: form.id), params:)
        }.to change { form.reload.send_copy_of_answers }.to("disabled")
      end

      it "displays a success flash message" do
        post(copy_of_answers_create_path(form_id: form.id), params:)
        expect(flash[:success]).to eq(I18n.t("banner.success.form.copy_of_answers_disabled"))
      end
    end

    context "when the setting is unchanged" do
      let(:send_copy_of_answers_original_value) { "enabled" }
      let(:send_copy_of_answers) { "enabled" }

      it "does not display a flash message" do
        post(copy_of_answers_create_path(form_id: form.id), params:)
        expect(flash[:success]).to be_nil
      end
    end

    context "when the send_copy_of_answers value is invalid" do
      let(:send_copy_of_answers) { "invalid_value" }

      it "renders the new template with unprocessable content status" do
        post(copy_of_answers_create_path(form_id: form.id), params:)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to have_rendered :new
        expect(response.body).to include("Sorry, there was a problem. Please try again.")
      end
    end

    context "when the user is not authorized" do
      let(:current_user) { build :user }

      it "returns 403" do
        post(copy_of_answers_create_path(form_id: form.id), params:)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
