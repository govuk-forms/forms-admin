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
              goto: "page_#{pages.third.id}",
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

      context "when new_exit_page is passed in the params" do
        let(:valid_params) do
          super().merge(
            new_exit_page: pages.first.id,
          )
        end

        it "redirects to the new exit page path" do
          post routes_path(form.id), params: valid_params
          expect(response).to redirect_to(new_exit_page_path(form, pages.first.id))
        end
      end

      context "when form question section is marked as complete" do
        it "marks the question section as incomplete" do
          form.update!(question_section_completed: true)

          expect {
            post routes_path(form.id), params: valid_params
          }.to change { form.reload.question_section_completed? }.from(true).to(false)
        end

        context "when no changes have been made to routes" do
          it "does not mark the question section as incomplete" do
            post routes_path(form.id), params: valid_params

            form.update!(question_section_completed: true)

            expect {
              post routes_path(form.id), params: valid_params
            }.not_to change { form.reload.question_section_completed? }.from(true)
          end
        end
      end
    end

    context "when a route goes to an exit page that was created from a condition" do
      let(:pages) { [create(:page, :with_selection_settings, form:)] }
      let(:routing_page) { pages.first }
      let!(:condition) do
        create :condition, routing_page:, check_page: routing_page,
                           answer_value: routing_page.answer_settings.selection_options.first.name,
                           exit_page_heading: "Old heading", exit_page_markdown: "Old markdown"
      end
      let(:exit_page) { condition.reload.exit_page }
      let(:valid_params) do
        {
          forms_routes_input: {
            routes_attributes: {
              "0" => {
                id: condition.id,
                page_id: routing_page.id,
                answer_value: condition.answer_value,
                goto: GotoValue::ExitPage.new(exit_page.id).to_s,
              },
            },
          },
        }
      end

      before do
        exit_page.update!(heading_cy: "Welsh heading", markdown_cy: "Welsh markdown")
      end

      it "does not undo changes made to the exit page" do
        put exit_page_path(form_id: form.id, page_id: routing_page.id, id: exit_page.id),
            params: { pages_update_exit_page_input: { heading: "New heading", markdown: "New markdown" } }

        post routes_path(form.id), params: valid_params

        expect(exit_page.reload).to have_attributes(heading: "New heading", markdown: "New markdown", heading_cy: "Welsh heading", markdown_cy: "Welsh markdown")
      end

      it "does not remove Welsh translations when the English is edited through the condition" do
        put conditions_exit_page_update_path(form_id: form.id, page_id: routing_page.id, condition_id: condition.id),
            params: { conditions_update_exit_page_input: { exit_page_heading: "New heading", exit_page_markdown: "New markdown" } }

        expect(exit_page.reload).to have_attributes(heading: "New heading", markdown: "New markdown", heading_cy: "Welsh heading", markdown_cy: "Welsh markdown")
      end
    end

    context "when the user is not in the form's group" do
      let(:membership) { nil }

      it "returns a forbidden status code" do
        post routes_path(form.id), params: valid_params
        expect(response).to have_http_status :forbidden
      end
    end
  end
end
