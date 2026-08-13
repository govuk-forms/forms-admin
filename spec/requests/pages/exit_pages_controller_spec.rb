require "rails_helper"

RSpec.describe Pages::ExitPagesController, :feature_multiple_branches, type: :request do
  let(:form) { create(:form, :with_group, :with_pages, pages: [create(:page, :with_selection_settings)], group:) }
  let(:page) { form.pages.first }
  let(:group) { create(:group, organisation: test_org, memberships: [create(:membership, user: standard_user)]) }

  before do
    login_as standard_user
  end

  describe "#new" do
    before do
      get new_exit_page_path(form_id: form.id, page_id: page.id)
    end

    it "renders the template" do
      expect(response).to have_rendered("exit_pages/new")
      expect(response.body).to include("Add exit page")
    end

    context "when the multiple branches feature is not enabled", feature_multiple_branches: false do
      it "is forbidden" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the user is not in the form's group" do
      let(:group) { create(:group, organisation: test_org, memberships: []) }

      it "returns a forbidden status code" do
        expect(response).to have_http_status :forbidden
      end
    end
  end

  describe "#create" do
    let(:params) { { pages_exit_page_input: { heading: "Exit Page Heading", markdown: "Exit Page Markdown" } } }

    before do
      post exit_pages_path(form_id: form.id, page_id: page.id, params:)
    end

    it "creates an exit page" do
      expect(response).to redirect_to(routes_path(form.id))
      expect(flash[:success]).to eq(I18n.t("banner.success.exit_page_saved"))

      exit_page = page.reload.exit_pages.first

      expect(exit_page.heading).to eq("Exit Page Heading")
      expect(exit_page.markdown).to eq("Exit Page Markdown")
    end

    context "when the user doesn't submit valid params" do
      let(:params) { { pages_exit_page_input: { heading: nil, markdown: nil } } }

      it "renders the exit page template" do
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template("exit_pages/new")
      end
    end

    context "when the multiple branches feature is not enabled", feature_multiple_branches: false do
      it "is forbidden" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the user is not in the form's group" do
      let(:group) { create(:group, organisation: test_org, memberships: []) }

      it "returns a forbidden status code" do
        expect(response).to have_http_status :forbidden
      end
    end
  end

  describe "#edit" do
    let(:exit_page) { create(:exit_page, question_page: page) }

    before do
      get edit_exit_page_path(form.id, page.id, exit_page.id)
    end

    it "renders the template" do
      expect(response).to have_rendered("exit_pages/edit")
      expect(response.body).to include("Edit exit page")
    end

    context "when the multiple branches feature is not enabled", feature_multiple_branches: false do
      it "is forbidden" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the user is not in the form's group" do
      let(:group) { create(:group, organisation: test_org, memberships: []) }

      it "returns a forbidden status code" do
        expect(response).to have_http_status :forbidden
      end
    end
  end

  describe "#update" do
    let(:exit_page) { create(:exit_page, question_page: page) }

    before do
      patch exit_page_path(form.id, page.id, exit_page.id), params: { pages_update_exit_page_input: { heading: "Exit Page Heading", markdown: "Exit Page Markdown" } }
    end

    it "updates the exit page" do
      expect(response).to redirect_to(routes_path(form.id))
      expect(flash[:success]).to eq(I18n.t("banner.success.exit_page_saved"))

      expect(exit_page.reload.heading).to eq("Exit Page Heading")
      expect(exit_page.reload.markdown).to eq("Exit Page Markdown")
    end

    context "when the exit page is invalid" do
      before do
        patch exit_page_path(form.id, page.id, exit_page.id), params: { pages_update_exit_page_input: { heading: nil, markdown: nil } }
      end

      it "renders the exit page template" do
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template("exit_pages/edit")
      end
    end

    context "when the multiple branches feature is not enabled", feature_multiple_branches: false do
      it "is forbidden" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the user is not in the form's group" do
      let(:group) { create(:group, organisation: test_org, memberships: []) }

      it "returns a forbidden status code" do
        expect(response).to have_http_status :forbidden
      end
    end
  end

  describe "#delete" do
    let(:exit_page) { create(:exit_page, question_page: page) }

    before do
      get delete_exit_page_path(form_id: form.id, page_id: page.id, id: exit_page.id)
    end

    it "renders the template" do
      expect(response).to have_rendered("exit_pages/delete")
      expect(response.body).to include("Are you sure you want to delete this exit page?")
    end

    context "when the multiple branches feature is not enabled", feature_multiple_branches: false do
      it "is forbidden" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the user is not in the form's group" do
      let(:group) { create(:group, organisation: test_org, memberships: []) }

      it "returns a forbidden status code" do
        expect(response).to have_http_status :forbidden
      end
    end
  end

  describe "#destroy" do
    subject!(:exit_page) { create(:exit_page, question_page: page) }

    let(:form) { super().tap { |f| f.question_section_completed = true } }
    let(:exit_page_url) { exit_page_path(form_id: form.id, page_id: page.id, id: exit_page.id) }
    let(:params) { { pages_delete_exit_page_input: { confirm: "yes" } } }

    it "deletes the exit page" do
      expect { delete exit_page_url, params: }.to change(page.reload.exit_pages, :count).by(-1)
    end

    it "sets question_section_completed to false and updates the draft" do
      expect { delete exit_page_url, params: }.to change { form.reload.question_section_completed? }.from(true).to(false)
        .and(change { form.draft_form_document.reload.updated_at })
    end

    it "redirects to the routes page" do
      delete(exit_page_url, params:)
      expect(response).to redirect_to(routes_path(form_id: form.id))
    end

    it "displays a success flash message" do
      delete(exit_page_url, params:)
      expect(flash[:success]).to eq(I18n.t("banner.success.exit_page_deleted"))
    end

    context "when not confirmed" do
      let(:params) { { pages_delete_exit_page_input: { confirm: "no" } } }

      it "redirects to the edit exit page page" do
        delete(exit_page_url, params:)
        expect(response).to redirect_to(edit_exit_page_path(form_id: form.id, page_id: page.id, id: exit_page.id))
      end
    end

    context "when the params are invalid" do
      let(:params) { { pages_delete_exit_page_input: { confirm: nil } } }

      it "returns an unprocessable content response" do
        delete(exit_page_url, params:)
        expect(response).to have_http_status :unprocessable_content
      end
    end
  end

  describe "#render_preview" do
    let(:markdown) { "[Markdown](https://example.com)" }

    before do
      post render_preview_exit_pages_path(form_id: form.id, page_id: page.id), params: { markdown: }
    end

    it "returns a JSON object containing the converted HTML" do
      expected_preview_html = <<~HTML.strip
        <p class="govuk-body"><a href="https://example.com" class="govuk-link" rel="noreferrer noopener" target="_blank">Markdown (opens in new tab)</a></p>
      HTML

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq({
        preview_html: expected_preview_html,
        errors: [],
      }.to_json)
    end

    context "when markdown is blank" do
      let(:markdown) { "" }

      it "returns a JSON object containing the converted HTML" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq({ preview_html: I18n.t("markdown_editor.no_markdown_content_html"), errors: [] }.to_json)
      end
    end

    context "when the multiple branches feature is not enabled", feature_multiple_branches: false do
      it "is forbidden" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the user is not in the form's group" do
      let(:group) { create(:group, organisation: test_org, memberships: []) }

      it "returns a forbidden status code" do
        expect(response).to have_http_status :forbidden
      end
    end
  end
end
