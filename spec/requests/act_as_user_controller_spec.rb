require "rails_helper"

RSpec.describe ActAsUserController, type: :request do
  let(:act_as_user_enabled) { true }

  before do
    allow(Settings).to receive(:act_as_user_enabled).and_return(act_as_user_enabled)
    login_as_super_admin_user
  end

  describe "POST start" do
    context "when the act_as_user_enabled setting is off" do
      let(:act_as_user_enabled) { false }

      it "raises an error" do
        post act_as_user_start_path(standard_user)

        expect(response).to have_http_status(404)
      end
    end

    context "when the user is not a super_admin" do
      before do
        login_as_standard_user
      end

      it "redirects to the root page" do
        post act_as_user_start_path(standard_user)

        expect(response).to have_http_status(403)
      end
    end

    context "when the target user is a super_admin" do
      let(:other_super_admin) { create(:super_admin_user) }

      it "returns an unauthorized response" do
        post act_as_user_start_path(other_super_admin)

        expect(request.env["warden"].user.id).to eq(super_admin_user.id)
      end
    end

    context "when the target user has been denied access" do
      let(:access_denied_user) { create(:user, has_access: false) }

      it "returns an unauthorized response" do
        post act_as_user_start_path(access_denied_user)

        expect(request.env["warden"].user.id).to eq(super_admin_user.id)
      end
    end

    context "when the target user does not have an organisation" do
      let(:user_without_organisation) { create(:user, :with_no_org) }

      it "does not change the acting user" do
        post act_as_user_start_path(user_without_organisation)

        expect(request.env["warden"].user.id).to eq(super_admin_user.id)
      end
    end

    context "when the target user does not have a name" do
      let(:user_without_name) { create(:user, name: nil) }

      it "does not change the acting user" do
        post act_as_user_start_path(user_without_name)

        expect(request.env["warden"].user.id).to eq(super_admin_user.id)
      end
    end

    it "changes the acting user" do
      post act_as_user_start_path(standard_user)

      expect(request.env["warden"].user.id).to eq(standard_user.id)
      expect(session[:original_user_id]).to eq(super_admin_user.id)
    end
  end

  describe "GET stop" do
    before do
      allow(Settings).to receive(:act_as_user_enabled).and_return(act_as_user_enabled)
      login_as_super_admin_user
    end

    context "when not acting as a user" do
      it "does not change the current user" do
        get act_as_user_stop_path

        expect(request.env["warden"].user.id).to eq(super_admin_user.id)
        expect(session[:original_user_id]).to be_nil
      end
    end

    context "when acting as a user" do
      let(:controller_spy) do
        controller_spy = described_class.new
        allow(described_class).to receive(:new).and_return(controller_spy)
        controller_spy
      end

      before do
        post act_as_user_start_path(standard_user)

        allow(controller_spy).to receive(:redirect_if_account_not_completed).and_call_original
      end

      it "skips the redirect_if_account_not_completed action" do
        get act_as_user_stop_path

        expect(controller_spy).not_to have_received(:redirect_if_account_not_completed)
      end

      it "changes back to the original user" do
        get act_as_user_stop_path

        expect(request.env["warden"].user.id).to eq(super_admin_user.id)
        expect(session[:original_user_id]).to be_nil
      end
    end
  end
end
