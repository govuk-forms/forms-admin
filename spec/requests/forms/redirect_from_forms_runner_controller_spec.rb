require "rails_helper"

RSpec.describe Forms::RedirectFromFormsRunnerController, type: :request do
  let(:form) { create(:form, :with_pages) }

  let(:group) { create(:group, organisation: standard_user.organisation) }
  let(:membership) { create :membership, group:, user: standard_user }

  before do
    membership
    login_as_standard_user
  end

  describe "#redirect_to_edit_question" do
    context "with a form in a group that the user is not a member of" do
      let(:form) { create(:form, :with_pages) }
      let(:other_group) { create(:group) }

      before do
        other_group.group_forms.create!(form_id: form.id)
        get edit_question_by_external_id_path(form_id: form.id, page_external_id: form.pages.first.external_id)
      end

      it "Renders the forbidden page" do
        expect(response).to render_template("errors/forbidden")
      end

      it "Returns a 403 status" do
        expect(response.status).to eq(403)
      end
    end

    context "with a form in a group that the user is a member of" do
      let(:page) { form.pages.second }
      let(:external_id) { page.external_id }

      before do
        group.group_forms.create!(form_id: form.id)
        get edit_question_by_external_id_path(form_id: form.id, page_external_id: external_id)
      end

      context "when the page exists for the form" do
        it "returns a 302 status code" do
          expect(response).to have_http_status(302)
        end

        it "redirects to the edit question page" do
          expect(response).to redirect_to(edit_question_path(form_id: form.id, page_id: page.id))
        end
      end

      context "when the page is in a different form" do
        let(:page) { create(:page) }

        it "returns a 404" do
          expect(response).to have_http_status(404)
        end
      end

      context "when the page does not exist" do
        let(:external_id) { "does-not-exist" }

        it "returns a 404" do
          expect(response).to have_http_status(404)
        end
      end
    end
  end

  describe "#routes" do
    let(:page) { form.pages.second }
    let(:external_id) { page.external_id }

    before do
      group.group_forms.create!(form_id: form.id)
      get show_routes_by_external_id_path(form_id: form.id, page_external_id: external_id)
    end

    context "when the page exists for the form" do
      it "returns a 302 status code" do
        expect(response).to have_http_status(302)
      end

      context "when the multiple branches feature is not enabled", feature_multiple_branches: false do
        it "redirects to the show routes page" do
          expect(response).to redirect_to(show_routes_path(form_id: form.id, page_id: page.id))
        end
      end

      context "when the multiple branches feature is enabled", :feature_multiple_branches do
        it "redirects to the edit routes page" do
          expect(response).to redirect_to(routes_path(form_id: form.id, anchor: page.page_position_id))
        end
      end
    end

    context "when the page is in a different form" do
      let(:page) { create(:page) }

      it "returns a 404" do
        expect(response).to have_http_status(404)
      end
    end

    context "when the page does not exist" do
      let(:external_id) { "does-not-exist" }

      it "returns a 404" do
        expect(response).to have_http_status(404)
      end
    end
  end
end
