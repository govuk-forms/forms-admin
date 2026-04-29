require "rails_helper"

RSpec.describe RoutesController, type: :request do
  let(:form) { create(:form, :with_group, group:) }
  let(:membership) { create :membership, group:, user: standard_user }
  let(:group) { create(:group, multiple_branches_enabled: true) }

  before do
    membership
    login_as_standard_user
  end

  describe "#show" do
    it "returns a 200 status code" do
      get routes_path(form.id)
      expect(response).to have_http_status(:ok)
    end

    it "renders the routes#show template" do
      get routes_path(form.id)
      expect(response).to render_template("routes/show")
    end

    context "when the user is not in the form's group" do
      let(:membership) { nil }

      it "returns a forbidden status code" do
        get routes_path(form.id)
        expect(response).to have_http_status :forbidden
      end
    end

    context "when the multiple_branches feature is not enabled" do
      let(:group) { create(:group, multiple_branches_enabled: false) }

      it "returns a 404" do
        get routes_path(form.id)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
