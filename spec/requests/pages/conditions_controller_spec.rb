require "rails_helper"

RSpec.describe Pages::ConditionsController, type: :request do
  let(:form) { create :form, :ready_for_routing }
  let(:pages) { form.pages }
  let(:page) do
    pages.first.tap do |first_page|
      first_page.is_optional = false
      first_page.answer_type = "selection"
      first_page.answer_settings = DataStruct.new(
        only_one_option: true,
        selection_options: [OpenStruct.new(attributes: { name: "Option 1" }),
                            OpenStruct.new(attributes: { name: "Option 2" })],
      )
    end
  end

  let(:submit_result) { true }

  let(:group) { create(:group, organisation: standard_user.organisation) }
  let(:user) { standard_user }

  before do
    Membership.create!(group_id: group.id, user: standard_user, added_by: standard_user)
    GroupForm.create!(form_id: form.id, group_id: group.id)
    login_as user
  end

  describe "#routing_page" do
    before do
      get routing_page_path(form_id: form.id)
    end

    it "renders the routing page template" do
      expect(response).to render_template("pages/conditions/routing_page")
    end
  end

  describe "#set_routing_page" do
    let(:params) { { pages_routing_page_input: { routing_page_id: page.id } } }

    context "when the page doesn't have a condition associated with it" do
      before do
        post routing_page_path(form_id: form.id, params:)
      end

      it "redirects the user to the new conditions page" do
        expect(response).to redirect_to new_condition_path(form.id, page.id)
      end
    end

    context "when the page already has a condition associated with it" do
      before do
        create :condition, routing_page_id: page.id, check_page_id: page.id, goto_page_id: pages.last.id

        post routing_page_path(form_id: form.id, params:)
      end

      it "redirects the user to the question routes page" do
        expect(response).to redirect_to show_routes_path(form.id, page.id)
      end
    end

    context "when user should not be allowed to add routes to pages" do
      let(:user) { build :user }

      before do
        post routing_page_path(form_id: form.id, params:)
      end

      it "Renders the forbidden page" do
        expect(response).to render_template("errors/forbidden")
      end

      it "Returns a 403 status" do
        expect(response.status).to eq(403)
      end
    end

    context "when the routing page is not set" do
      let(:params) { { pages_routing_page_input: { routing_page_id: nil } } }

      before do
        post routing_page_path(form_id: form.id, params:)
      end

      it "renders the routing page view" do
        expect(response).to render_template("pages/conditions/routing_page")
      end

      it "Returns a 422 status" do
        expect(response.status).to eq(422)
      end
    end
  end

  describe "#new" do
    before do
      get new_condition_path(form_id: form.id, page_id: page.id)
    end

    it "renders the new condition page template" do
      expect(response).to render_template("pages/conditions/new")
    end

    context "when user should not be allowed to add routes to pages" do
      let(:form) { create :form }
      let(:pages) { [create(:page)] }

      it "Renders the forbidden page" do
        expect(response).to render_template("errors/forbidden")
      end

      it "Returns a 403 status" do
        expect(response.status).to eq(403)
      end
    end
  end

  describe "#create" do
    let(:params) { { pages_conditions_input: { routing_page_id: page.id, check_page_id: page.id, goto_page_id: pages.last.id, answer_value: "Wales" } } }

    context "when the page doesn't have an existing condition" do
      before do
        post create_condition_path(form_id: form.id, page_id: page.id, params:)
      end

      it "redirects to the page list" do
        expect(response).to redirect_to show_routes_path(form_id: form.id, page_id: page.id)
      end

      it "creates the condition" do
        expect(page.reload.routing_conditions.count).to eq(1)
      end

      it "has the expected attributes" do
        condition = page.reload.routing_conditions.first
        expect(condition.answer_value).to eq("Wales")
        expect(condition.check_page_id).to eq(page.id)
        expect(condition.routing_page_id).to eq(page.id)
        expect(condition.goto_page_id).to eq(pages.last.id)
        expect(condition.skip_to_end).to be(false)
      end

      it "updates the form document" do
        routing_conditions = form.reload.draft_form_document.content["steps"][0]["routing_conditions"]
        expect(routing_conditions).to contain_exactly(
          hash_including(
            "routing_page_id" => page.external_id,
            "answer_value" => "Wales",
          ),
        )
      end

      it "displays success message" do
        follow_redirect!
        expect(response.body).to include(I18n.t("banner.success.route_created", route_number: 1))
      end

      context "when the goto page is an exit page" do
        let(:params) { { pages_conditions_input: { routing_page_id: page.id, check_page_id: page.id, goto_page_id: "create_exit_page", answer_value: "Wales" } } }
        let(:group) { create(:group, organisation: standard_user.organisation) }

        it "redirects to the new exit page" do
          expect(response).to redirect_to conditions_exit_page_new_path(form_id: form.id, page_id: page.id, answer_value: "Wales")
        end
      end

      context "when form submit fails" do
        let(:params) { { pages_conditions_input: { routing_page_id: nil, check_page_id: nil, goto_page_id: nil, answer_value: nil } } }

        it "return 422 error code" do
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "renders new page" do
          expect(response).to render_template("pages/conditions/new")
        end
      end

      context "when the form is not in a state to which routes can be added" do
        let(:form) { create :form, :with_pages }

        it "Renders the forbidden page" do
          expect(response).to render_template("errors/forbidden")
        end

        it "Returns a 403 status" do
          expect(response.status).to eq(403)
        end
      end
    end

    context "when the page already has a condition associated with it" do
      before do
        create :condition, routing_page_id: page.id, check_page_id: page.id, goto_page_id: pages.last.id
      end

      it "does not create the condition and redirects the user to the question routes page" do
        expect {
          post create_condition_path(form_id: form.id, page_id: page.id, params:)
        }.not_to change(Condition, :count)
      end

      it "redirects to the question routes page" do
        post create_condition_path(form_id: form.id, page_id: page.id, params:)
        expect(response).to redirect_to show_routes_path(form_id: form.id, page_id: page.id)
      end
    end
  end

  describe "#edit" do
    let(:condition) { create :condition, routing_page_id: page.id, check_page_id: page.id, answer_value: "Wales", goto_page_id: pages.third.id }

    # Use instance variable to allow asserting instance receives method
    let(:conditions_input) { @conditions_input } # rubocop:disable RSpec/InstanceVariable

    before do
      allow(Pages::ConditionsInput).to receive(:new).and_wrap_original do |original_method, *args, **kwargs|
        @conditions_input = original_method.call(*args, **kwargs)
        allow(conditions_input).to receive(:check_errors_from_api).and_call_original
        allow(conditions_input).to receive(:assign_condition_values).and_call_original
        conditions_input
      end

      get edit_condition_path(form_id: form.id, page_id: page.id, condition_id: condition.id)
    end

    it "Checks the errors from the API response" do
      expect(conditions_input).to have_received(:check_errors_from_api).exactly(1).times
    end

    it "Calls assign_condition_values" do
      expect(conditions_input).to have_received(:assign_condition_values).exactly(1).times
    end

    it "renders the new condition page template" do
      expect(response).to render_template("pages/conditions/edit")
    end

    context "when user should not be allowed to add routes to pages" do
      let(:user) { build :user }

      it "Renders the forbidden page" do
        expect(response).to render_template("errors/forbidden")
      end

      it "Returns a 403 status" do
        expect(response.status).to eq(403)
      end
    end
  end

  describe "#update" do
    let(:params) { { pages_conditions_input: { routing_page_id: page.id, check_page_id: page.id, goto_page_id: pages.last.id, answer_value: "England" } } }
    let(:condition) { create :condition, routing_page_id: page.id, check_page_id: page.id, goto_page_id: pages.last.id, answer_value: "Wales" }

    it "redirects to the page list" do
      put update_condition_path(form_id: form.id, page_id: page.id, condition_id: condition.id, params:)
      expect(response).to redirect_to show_routes_path(form_id: form.id, page_id: page.id)
    end

    it "updates the condition" do
      expect {
        put update_condition_path(form_id: form.id, page_id: page.id, condition_id: condition.id, params:)
      }.to(change { condition.reload.attributes })
    end

    it "updates the form document" do
      put update_condition_path(form_id: form.id, page_id: page.id, condition_id: condition.id, params:)
      routing_conditions = form.reload.draft_form_document.content["steps"][0]["routing_conditions"]
      expect(routing_conditions).to contain_exactly(
        a_hash_including(
          "answer_value" => "England",
        ),
      )
    end

    it "displays success message" do
      put update_condition_path(form_id: form.id, page_id: page.id, condition_id: condition.id, params:)
      follow_redirect!
      expect(response.body).to include(I18n.t("banner.success.route_updated", question_number: pages.first.position))
    end

    context "when form submit fails" do
      let(:params) { { pages_conditions_input: { routing_page_id: nil, check_page_id: nil, goto_page_id: nil, answer_value: nil } } }

      before do
        put update_condition_path(form_id: form.id, page_id: page.id, condition_id: condition.id, params:)
      end

      it "return 422 error code" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "renders new page" do
        expect(response).to render_template("pages/conditions/edit")
      end
    end

    context "when the form is submitted creates an exit page" do
      let(:group) { create(:group, organisation: standard_user.organisation) }
      let(:params) { { pages_conditions_input: { routing_page_id: 1, check_page_id: 1, goto_page_id: "create_exit_page", answer_value: "Wales" } } }

      it "redirects to the edit exit page" do
        put update_condition_path(form_id: form.id, page_id: page.id, condition_id: condition.id, params:)
        expect(response).to redirect_to conditions_exit_page_edit_path(form_id: form.id, page_id: page.id, condition_id: condition.id)
      end
    end

    context "when user should not be allowed to add routes to pages" do
      let(:user) { build :user }

      before do
        put update_condition_path(form_id: form.id, page_id: page.id, condition_id: condition.id, params:)
      end

      it "Renders the forbidden page" do
        expect(response).to render_template("errors/forbidden")
      end

      it "Returns a 403 status" do
        expect(response.status).to eq(403)
      end
    end

    context "when the condition is already an exit page" do
      let(:condition) { create :condition, :with_exit_page, routing_page_id: page.id, check_page_id: page.id }

      context "when changing to a non-exit page" do
        let(:params) { { pages_conditions_input: { routing_page_id: 1, check_page_id: 1, goto_page_id: 3, answer_value: "Wales" } } }

        it "redirects to the confirm exit page deletion page" do
          put update_condition_path(form_id: form.id, page_id: page.id, condition_id: condition.id, params:)
          expect(response).to redirect_to confirm_change_exit_page_path(form_id: form.id, page_id: page.id, condition_id: condition.id, params: { answer_value: "Wales", goto_page_id: 3 })
        end

        it "does not update the condition" do
          expect {
            put update_condition_path(form_id: form.id, page_id: page.id, condition_id: condition.id, params:)
          }.not_to(change(condition, :attributes))
        end
      end

      context "when changing to an exit page" do
        let(:params) { { pages_conditions_input: { routing_page_id: 1, check_page_id: 1, goto_page_id: "exit_page", answer_value: "Wales" } } }

        it "redirects to the edit exit page" do
          put update_condition_path(form_id: form.id, page_id: page.id, condition_id: condition.id, params:)
          expect(response).to redirect_to show_routes_path(form_id: form.id, page_id: page.id)
        end
      end
    end
  end

  describe "#delete" do
    let(:condition) { create :condition, id: 1, routing_page_id: page.id, check_page_id: page.id, answer_value: "Wales", goto_page_id: pages.last.id }

    before do
      get delete_condition_path(form_id: form.id, page_id: page.id, condition_id: condition.id)
    end

    it "renders the delete condition page template" do
      expect(response).to render_template("pages/conditions/delete")
    end

    context "when user should not be allowed to add routes to pages" do
      let(:user) { build :user }

      it "Renders the forbidden page" do
        expect(response).to render_template("errors/forbidden")
      end

      it "Returns a 403 status" do
        expect(response.status).to eq(403)
      end
    end
  end

  describe "#destroy" do
    let(:condition) { create :condition, id: 1, routing_page_id: page.id, check_page_id: page.id, answer_value: "Wales", goto_page_id: pages.last.id }
    let(:confirm) { "yes" }

    before do
      delete destroy_condition_path(form_id: form.id,
                                    page_id: page.id,
                                    condition_id: condition.id,
                                    params: { pages_delete_condition_input: { confirm: } })
    end

    context "when the destroy is successful" do
      it "redirects to the page list" do
        expect(response).to redirect_to form_pages_path(form_id: form.id)
      end

      it "displays success message" do
        follow_redirect!
        expect(response.body).to include(I18n.t("banner.success.route_deleted", question_number: 1))
      end

      it "updates the form document" do
        routing_conditions = form.reload.draft_form_document.content["steps"][0]["routing_conditions"]
        expect(routing_conditions).to be_empty
      end

      context "when confirm deletion is false" do
        let(:confirm) { "no" }

        it "redirects to edit the condition" do
          expect(response).to redirect_to edit_condition_path(form_id: form.id, page_id: page.id, condition_id: condition.id)
        end
      end
    end

    context "when form submit fails" do
      let(:confirm) { nil }

      it "return 422 error code" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "renders the delete page" do
        expect(response).to render_template("pages/conditions/delete")
      end
    end

    context "when user should not be allowed to add routes to pages" do
      let(:user) { build :user }

      it "Renders the forbidden page" do
        expect(response).to render_template("errors/forbidden")
      end

      it "Returns a 403 status" do
        expect(response.status).to eq(403)
      end
    end
  end

  describe "#confirm_delete_exit_page" do
    let(:condition) { create :condition, :with_exit_page, routing_page_id: page.id, check_page_id: page.id }
    let(:answer_value) { "Option 1" }
    let(:goto_page_id) { "2" }

    before do
      get confirm_change_exit_page_path(
        form_id: form.id,
        page_id: page.id,
        condition_id: condition.id,
        answer_value: answer_value,
        goto_page_id: goto_page_id,
      )
    end

    it "renders the confirm_delete_exit_page template" do
      expect(response).to render_template("pages/conditions/confirm_delete_exit_page")
    end

    context "when user should not be allowed to add routes to pages" do
      let(:user) { build :user }

      it "Renders the forbidden page" do
        expect(response).to render_template("errors/forbidden")
      end

      it "Returns a 403 status" do
        expect(response.status).to eq(403)
      end
    end
  end

  describe "#update_change_exit_page" do
    let(:condition) { create :condition, :with_exit_page, routing_page_id: page.id, check_page_id: page.id }
    let(:answer_value) { "Option 1" }
    let(:goto_page_id) { pages.last.id }
    let(:confirm) { "yes" }
    let(:update_condition_result) { nil }

    before do
      allow(Pages::ConditionsInput).to receive(:new).and_wrap_original do |original_method, *args, **kwargs|
        conditions_input = original_method.call(*args, **kwargs)
        allow(conditions_input).to receive(:update_condition).and_return(update_condition_result) unless update_condition_result.nil?
        allow(conditions_input).to receive(:check_errors_from_api).and_call_original
        allow(conditions_input).to receive(:assign_condition_values).and_call_original
        conditions_input
      end

      post update_change_exit_page_path(
        form_id: form.id,
        page_id: page.id,
        condition_id: condition.id,
        answer_value: answer_value,
        goto_page_id: goto_page_id,
        params: { pages_delete_exit_page_input: { confirm: } },
      )
    end

    it "clears the exit page fields" do
      expect(condition.reload.exit_page_heading).to be_nil
      expect(condition.reload.exit_page_markdown).to be_nil
    end

    it "redirects to the question routes page" do
      expect(response).to redirect_to show_routes_path(form_id: form.id, page_id: page.id)
    end

    context "when confirm is not 'yes'" do
      let(:confirm) { "no" }

      it "redirects to the edit condition page" do
        expect(response).to redirect_to edit_condition_path(form_id: form.id, page_id: page.id, condition_id: condition.id)
      end
    end

    context "when confirm is missing or invalid" do
      let(:confirm) { nil }

      it "returns a 422 error code" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "renders the confirm_delete template" do
        expect(response).to render_template("pages/conditions/confirm_delete_exit_page")
      end
    end

    context "when updating the condition fails" do
      let(:update_condition_result) { false }

      it "returns a 422 error code" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "renders the conditions/edit template" do
        expect(response).to render_template("pages/conditions/edit")
      end
    end

    context "when condition is not an exit page" do
      let(:condition) { create :condition, routing_page_id: page.id, check_page_id: page.id, goto_page_id: pages.last.id }

      it "redirects to the form pages path" do
        expect(response).to redirect_to form_pages_path(form_id: form.id)
      end
    end

    context "when user should not be allowed to add routes to pages" do
      let(:user) { build :user }

      it "Renders the forbidden page" do
        expect(response).to render_template("errors/forbidden")
      end

      it "Returns a 403 status" do
        expect(response.status).to eq(403)
      end
    end
  end
end
