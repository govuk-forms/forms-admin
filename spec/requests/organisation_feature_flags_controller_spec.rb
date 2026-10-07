require "rails_helper"

RSpec.describe OrganisationFeatureFlagsController, type: :request do
  # No feature is organisation-scoped yet, so use an existing boolean column as a stand-in flag
  let(:feature_flag) { "internal" }
  let(:organisation) { create :organisation, slug: "department-for-testing", feature_flag => false }
  let(:path) { organisation_feature_flags_path(organisation) }

  before do
    allow(Organisation).to receive(:feature_flag_attributes).and_return([feature_flag])
  end

  describe "#edit" do
    context "when the user is not a super admin" do
      before do
        login_as_standard_user

        get path
      end

      it "returns http code 403 and renders forbidden" do
        expect(response).to have_http_status(:forbidden)
        expect(response).to render_template("errors/forbidden")
      end
    end

    context "when the user is not a super admin and the organisation does not exist" do
      before do
        login_as_standard_user

        get organisation_feature_flags_path(organisation_id: 0)
      end

      it "returns http code 403 so that it does not reveal which organisations exist" do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "renders the feature flags page" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:edit)
      end
    end

    context "when the organisation does not exist" do
      before do
        login_as_super_admin_user

        get organisation_feature_flags_path(organisation_id: 0)
      end

      it "returns http code 404" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "#update" do
    context "when the user is not a super admin" do
      before do
        login_as_standard_user

        post path, params: { feature_flags_input: { feature_flag => "true" } }
      end

      it "is forbidden and does not change the flag" do
        expect(response).to have_http_status(:forbidden)
        expect(organisation.reload[feature_flag]).to be(false)
      end
    end

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user
      end

      it "enables a feature flag and redirects to the organisation" do
        post path, params: { feature_flags_input: { feature_flag => "true" } }

        expect(organisation.reload[feature_flag]).to be(true)
        expect(response).to redirect_to(organisation_path(organisation))
        expect(flash[:success]).to eq(I18n.t("organisation_feature_flags.update.success"))
      end

      it "does not turn an enabled feature flag off" do
        organisation.update!(feature_flag => true)

        post path, params: { feature_flags_input: { feature_flag => "false" } }

        expect(organisation.reload[feature_flag]).to be(true)
      end

      it "does not show a success message when no flags have changed" do
        post path, params: { feature_flags_input: { feature_flag => "false" } }

        expect(response).to redirect_to(organisation_path(organisation))
        expect(flash[:success]).to be_nil
      end

      it "redirects without error when no params are submitted" do
        post path

        expect(response).to redirect_to(organisation_path(organisation))
        expect(flash[:success]).to be_nil
      end

      it "ignores attributes that are not feature flags" do
        post path, params: { feature_flags_input: { closed: "true" } }

        expect(organisation.reload.closed).to be(false)
      end
    end
  end
end
