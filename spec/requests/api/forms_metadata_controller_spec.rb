require "rails_helper"

RSpec.describe Api::FormsMetadataController, type: :request do
  let(:headers) { { "ACCEPT": "application/json" } }

  describe "#group" do
    context "when the form exists" do
      let(:form) { create(:form) }
      let(:group) { create(:group, organisation: test_org) }
      let(:group_admin) { create(:user, organisation: test_org) }

      before do
        organisation_admin_user
        create(:membership, user: group_admin, group:, role: :group_admin)
        create(:membership, user: create(:user, organisation: test_org), group:, role: :editor)

        group.group_forms.create!(form_id: form.id)
      end

      it "returns the group" do
        get("/api/v2/forms/#{form.id}/group", headers:)

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to eq({
          "external_id" => group.external_id,
          "name" => group.name,
          "group_admin_users" => [
            { "name" => group_admin.name, "email" => group_admin.email },
          ],
          "organisation" => {
            "id" => test_org.id,
            "name" => test_org.name,
            "organisation_admin_users" => [
              { "name" => organisation_admin_user.name, "email" => organisation_admin_user.email },
            ],
          },
        })
      end
    end

    context "when the form doesn't exist" do
      it "returns http not found" do
        get("/api/v2/forms/non-existent/group", headers:)

        expect(response).to have_http_status(:not_found)
        expect(response.headers["Content-Type"]).to eq("application/json; charset=utf-8")
      end
    end
  end
end
