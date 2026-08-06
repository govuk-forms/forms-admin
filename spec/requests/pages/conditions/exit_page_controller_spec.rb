require "rails_helper"

RSpec.describe Conditions::ExitPageController, type: :request do
  let(:form) { create :form, :ready_for_routing, id: 1 }
  let(:pages) { form.pages }
  let(:page) do
    pages.first.tap do |first_page|
      first_page.is_optional = false
      first_page.answer_type = "selection"
      first_page.answer_settings = DataStruct.new(
        only_one_option: true,
        selection_options: [OpenStruct.new(attributes: { name: answer_value }),
                            OpenStruct.new(attributes: { name: "Option 2" })],
      )
    end
  end
  let(:selected_page) { page }
  let(:answer_value) { "Option 1" }

  let(:group) { create(:group, organisation: standard_user.organisation) }
  let(:user) { standard_user }
  let(:condition) { create(:condition, :with_exit_page, routing_page_id: selected_page.id) }

  before do
    Membership.create!(group_id: group.id, user: standard_user, added_by: standard_user)
    GroupForm.create!(form_id: form.id, group_id: group.id)
    login_as user
  end

  describe "#new" do
    before do
      get conditions_exit_page_new_path(form_id: form.id, page_id: selected_page.id, answer_value: answer_value)
    end

    it "renders the new exit page template" do
      expect(response).to render_template("conditions/exit_page/new")
    end

    context "when user should not be allowed to add routes to pages" do
      let(:form) { create :form, id: 1 }
      let(:pages) { [create(:page)] }

      it "Renders the forbidden page" do
        expect(response.status).to eq(403)
        expect(response).to render_template("errors/forbidden")
      end
    end

    context "when there is no answer value param" do
      let(:answer_value) { nil }

      it "redirects to the new condition page" do
        expect(response).to redirect_to new_condition_path(form.id, selected_page.id)
      end
    end
  end

  describe "#create" do
    let(:params) { { conditions_exit_page_input: { exit_page_heading: "Exit Page Heading", exit_page_markdown: "Exit Page Markdown", answer_value: } } }

    before do
      post conditions_exit_page_create_path(form_id: form.id, page_id: selected_page.id, params:)
    end

    it "redirects to the show routes page with a success message" do
      expect(response).to redirect_to show_routes_path(form_id: form.id, page_id: selected_page.id)
      follow_redirect!
      expect(response.body).to include(I18n.t("banner.success.exit_page_created"))
    end

    context "when there is no answer value submitted" do
      let(:answer_value) { nil }

      it "redirects to the new condition page" do
        expect(response).to redirect_to new_condition_path(form.id, selected_page.id)
      end
    end

    context "when form submit fails" do
      let(:params) { { conditions_exit_page_input: { exit_page_heading: nil, exit_page_markdown: nil, answer_value: } } }

      it "renders new page with a 422 error code" do
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template("conditions/exit_page/new")
      end
    end

    context "when user should not be allowed to add routes to pages" do
      let(:form) { create :form, id: 1 }
      let(:pages) { [create(:page)] }

      it "Renders the forbidden page" do
        expect(response.status).to eq(403)
        expect(response).to render_template("errors/forbidden")
      end
    end
  end

  describe "#edit" do
    before do
      get conditions_exit_page_edit_path(form_id: form.id, page_id: selected_page.id, condition_id: condition.id)
    end

    it "renders the edit exit page template" do
      expect(response).to render_template("conditions/exit_page/edit")
    end
  end

  describe "#update" do
    let(:params) { { conditions_update_exit_page_input: { exit_page_heading: "Exit Page Heading", exit_page_markdown: "Exit Page Markdown" } } }

    before do
      put conditions_exit_page_update_path(form_id: form.id, page_id: selected_page.id, condition_id: condition.id, params:)
    end

    it "redirects to the edit condition page with a success message" do
      expect(response).to redirect_to edit_condition_path(form_id: form.id, page_id: selected_page.id, condition_id: condition.id)
      follow_redirect!
      expect(response.body).to include(I18n.t("banner.success.exit_page_updated"))
    end

    context "when form submit fails" do
      let(:params) { { conditions_update_exit_page_input: { exit_page_heading: nil, exit_page_markdown: nil } } }

      it "renders edit page with a 422 error code" do
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template("conditions/exit_page/edit")
      end
    end
  end

  describe "#delete" do
    before do
      allow(condition).to receive(:exit_page?).and_return(true)

      get conditions_exit_page_delete_path(form_id: form.id, page_id: selected_page.id, condition_id: condition.id)
    end

    it "renders the delete exit page template with the correct assignments" do
      expect(response).to render_template("conditions/exit_page/delete")
      expect(assigns(:exit_page)).to eq(condition)
      expect(assigns(:delete_exit_page_input)).to be_a(Conditions::DeleteExitPageInput)
    end

    context "when user should not be allowed to add/delete routes to pages" do
      let(:form) { create :form, id: 1 }
      let(:pages) { [create(:page)] }

      it "Renders the forbidden page" do
        expect(response.status).to eq(403)
        expect(response).to render_template("errors/forbidden")
      end
    end
  end

  describe "#destroy" do
    let(:params) { { conditions_delete_exit_page_input: { confirm: "yes" } } }

    before do
      delete conditions_exit_page_destroy_path(form_id: form.id, page_id: selected_page.id, condition_id: condition.id, params:)
    end

    it "redirects to form pages path with a success message and deletes the exit page" do
      expect(response).to redirect_to(new_condition_path(form.id, selected_page.id))
      follow_redirect!
      expect(response.body).to include(I18n.t("banner.success.exit_page_deleted"))
      expect(Condition.exists?(condition.id)).to be false
    end

    context "when confirmation is not provided" do
      let(:params) { { conditions_delete_exit_page_input: { confirm: nil } } }

      it "renders the delete template again" do
        expect(response).to render_template("conditions/exit_page/delete")
      end
    end

    context "when confirmation is no" do
      let(:params) { { conditions_delete_exit_page_input: { confirm: "no" } } }

      it "redirects to form pages path without deleting the exit page" do
        expect(response).to redirect_to(conditions_exit_page_edit_path(form.id, page.id, condition.id))
        expect(Condition.exists?(condition.id)).to be true
      end
    end

    context "when the condition is not an exit page" do
      let(:condition) { create :condition, routing_page_id: page.id, check_page_id: page.id, skip_to_end: true }

      before do
        allow(condition).to receive(:exit_page?).and_return(false)
        delete conditions_exit_page_destroy_path(form_id: form.id, page_id: selected_page.id, condition_id: condition.id, params:)
      end

      it "redirects to the form pages page" do
        expect(response).to redirect_to(form_pages_path(form.id))
      end
    end

    context "when user should not be allowed to add/delete routes to pages" do
      let(:form) { create :form, id: 1 }
      let(:pages) { [create(:page)] }

      it "Renders the forbidden page" do
        expect(response.status).to eq(403)
        expect(response).to render_template("errors/forbidden")
      end
    end
  end

  describe "#render_preview" do
    let(:markdown) { "[Markdown](https://example.com)" }
    let(:check_preview_validation) { "true" }

    before do
      post conditions_exit_page_render_preview_path(form_id: form.id, page_id: page.id), params: { markdown:, check_preview_validation: }
    end

    it "returns a JSON object containing the converted HTML" do
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq({
        preview_html: "<p class=\"govuk-body\"><a href=\"https://example.com\" class=\"govuk-link\" rel=\"noreferrer noopener\" target=\"_blank\">Markdown (opens in new tab)</a></p>",
        errors: [],
      }.to_json)
    end

    context "when markdown is blank" do
      let(:markdown) { "" }

      it "returns a JSON object containing the converted HTML with an error" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq({ preview_html: I18n.t("exit_page.no_content_added_html"), errors: [I18n.t("activemodel.errors.models.conditions/exit_page_input.attributes.exit_page_markdown.blank")] }.to_json)
      end

      context "when validation is disabled" do
        let(:check_preview_validation) { "false" }

        it "returns a JSON object containing the converted HTML" do
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq({ preview_html: I18n.t("exit_page.no_content_added_html"), errors: [] }.to_json)
        end
      end
    end
  end
end
