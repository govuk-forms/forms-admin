require "rails_helper"

RSpec.describe RoutesController, type: :request do
  let(:form) { create(:form, :with_group, group:) }
  let(:membership) { create :membership, group:, user: standard_user }
  let(:group) { create(:group, multiple_branches_enabled: true, organisation: standard_user.organisation) }

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
      let(:group) { create(:group, multiple_branches_enabled: false, organisation: standard_user.organisation) }

      it "returns a 404" do
        get routes_path(form.id)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "#create" do
    let!(:pages) { create_list(:page, 3, form:) }

    let(:valid_params) do
      {
        forms_routes_input: {
          routes_attributes: {
            "0" => {
              id: "",
              page_id: pages.first.id,
              answer_value: "",
              goto: pages.third.id,
            },
          },
        },
      }
    end

    context "with valid parameters" do
      it "creates a new routing condition" do
        expect { post routes_path(form.id), params: valid_params }.to change(Condition, :count).by(1)

        condition = Condition.last
        expect(condition.routing_page_id).to eq(pages.first.id)
        expect(condition.answer_value).to be_nil
        expect(condition.goto_page_id).to eq(pages.third.id)
      end

      it "redirects to the form page" do
        post routes_path(form.id), params: valid_params
        expect(response).to redirect_to(form_pages_path(form))
      end

      it "sets a success banner" do
        post routes_path(form.id), params: valid_params
        expect(flash[:success]).to eq I18n.t("banner.success.form.routing_saved")
      end
    end

    context "when the user is not in the form's group" do
      let(:membership) { nil }

      it "returns a forbidden status code" do
        post routes_path(form.id), params: valid_params
        expect(response).to have_http_status :forbidden
      end
    end

    context "when the multiple_branches feature is not enabled" do
      let(:group) { create(:group, multiple_branches_enabled: false, organisation: standard_user.organisation) }

      it "returns a 404" do
        post routes_path(form.id), params: valid_params
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
