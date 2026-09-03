require "rails_helper"

RSpec.describe PagesController, type: :request do
  let(:form) { create(:form) }

  let(:group) { create(:group, organisation: standard_user.organisation) }
  let(:membership) { create :membership, group:, user: standard_user }

  before do
    membership
    login_as_standard_user
  end

  shared_examples "logging", :capture_logging do
    it "logs the answer type" do
      expect(log_line["answer_type"]).to eq(page.answer_type)
    end
  end

  describe "#index" do
    let(:form) { create(:form, :with_pages) }
    let(:pages) { form.pages }

    context "with a form in a group that the user is a member of" do
      before do
        group.group_forms.create!(form_id: form.id)
        get form_pages_path(form.id)
      end

      it "returns a 200 status code" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the pages#index template" do
        expect(response).to render_template("pages/index")
      end
    end

    context "with a form in a group that the user is not a member of" do
      let(:form) { create(:form) }
      let(:other_group) { create(:group) }

      before do
        other_group.group_forms.create!(form_id: form.id)
        get form_pages_path(form.id)
      end

      it "Renders the forbidden page" do
        expect(response).to render_template("errors/forbidden")
      end

      it "Returns a 403 status" do
        expect(response.status).to eq(403)
      end
    end

    describe "when there are validation errors" do
      let(:form) { create(:form, :ready_for_routing) }

      before do
        create(:condition, routing_page_id: pages.first.id, check_page_id: pages.first.id, answer_value: nil, goto_page_id: pages.last.id)

        allow(standard_user).to receive(:collect_analytics?).and_return(collect_analytics)

        group.group_forms.create!(form_id: form.id)
        get form_pages_path(form.id)
      end

      context "when analytics is enabled" do
        let(:collect_analytics) { true }

        it "sends the validation errors to analytics" do
          page = Capybara.string(response.body)
          expect(page).to have_css("[data-analytics-events]", text: /answer_value_doesnt_exist/, visible: :all)
        end
      end

      context "when analytics is not enabled" do
        let(:collect_analytics) { false }

        it "does not send the validation errors to analytics" do
          page = Capybara.string(response.body)
          expect(page).not_to have_css("[data-analytics-events]", text: /answer_value_doesnt_exist/, visible: :all)
        end
      end
    end
  end

  describe "#start_new_question" do
    let(:original_draft_question) { create :draft_question, form_id: form.id, user: standard_user }

    before do
      GroupForm.create!(form_id: form.id, group_id: group.id)
    end

    it "clears draft questions data for current user and form" do
      original_draft_question # Setup initial draft question which will clear
      expect {
        get start_new_question_path(form_id: form.id)
      }.to change { DraftQuestion.exists?({ form_id: form.id, user: standard_user }) }.from(true).to(false)
    end

    it "does not clear draft questions data for a different form" do
      create :draft_question, form_id: 99, user: standard_user # Setup initial draft question which should not clear
      get start_new_question_path(form_id: form.id)
      expect(DraftQuestion.exists?({ form_id: 99, user: standard_user })).to be true
    end

    it "redirects to type_of_answer_create_path" do
      get start_new_question_path(form_id: form.id)
      expect(response).to redirect_to(type_of_answer_create_path(form_id: form.id))
    end
  end

  describe "#delete" do
    context "with a valid page" do
      let(:page) do
        create(
          :page,
          form:,
          question_text: "What is your work address?",
          hint_text: "This should be the location stated in your contract.",
          answer_type: "address",
          is_optional: false,
        )
      end

      let(:pages) { [page] }

      before do
        GroupForm.create!(form_id: form.id, group_id: group.id)
      end

      it "renders the delete page template" do
        get delete_page_path(form_id: form.id, page_id: page.id)

        expect(response).to render_template("pages/delete")
      end

      describe "logging" do
        before do
          get delete_page_path(form_id: form.id, page_id: page.id)
        end

        include_examples "logging"
      end

      context "when current user is not in group for form the page is in" do
        let(:membership) { nil }

        it "returns an error" do
          get delete_page_path(form_id: form.id, page_id: page.id)

          expect(response).to have_http_status :forbidden
        end
      end

      context "when page to delete has no routes" do
        it "does not render a warning" do
          get delete_page_path(form_id: form.id, page_id: page.id)

          expect(response.body).not_to include "Important"
        end
      end

      context "when page to delete is start of one or more routes" do
        let(:form) { create(:form, :ready_for_routing) }
        let(:pages) { form.pages }
        let(:page) { pages.first }

        before do
          create(:condition, routing_page_id: page.id, check_page_id: page.id, answer_value: "Red", goto_page_id: pages.last.id)
        end

        it "renders a warning about deleting this page" do
          get delete_page_path(form_id: form.id, page_id: page.id)

          assert_select(".govuk-notification-banner", count: 1) do
            assert_select "*", "Important"
            assert_select "h3", "Question #{page.position} is the start of a route"
            assert_select "p.govuk-body", /If you delete this question, its routes will also be deleted/
            assert_select "p.govuk-body a", "View question #{page.position}’s routes"
          end
        end
      end

      context "when page to delete is at the end of a route" do
        let(:form) { create(:form, :ready_for_routing) }
        let(:pages) { form.pages }
        let(:page) { pages.last }

        before do
          create(:condition, routing_page_id: pages.first.id, check_page_id: pages.first.id, answer_value: "Red", goto_page_id: page.id)
        end

        it "renders a warning about deleting this page" do
          get delete_page_path(form_id: form.id, page_id: page.id)

          assert_select(".govuk-notification-banner", count: 1) do
            assert_select "*", "Important"
            assert_select "h3", "Question 5 is at the end of a route"
            assert_select "p.govuk-body a", "Question 1’s route"
            assert_select "p.govuk-body", /Question 1’s route\s*goes to this question. If you delete this question, question 1’s routes will also be deleted./
          end
        end
      end

      context "when page to delete is start of a secondary skip route" do
        let(:form) { create(:form, :ready_for_routing) }
        let(:pages) { form.pages }
        let(:page) { pages.second }

        before do
          create(:condition, routing_page_id: pages.first.id, check_page_id: pages.first.id, answer_value: "Red", goto_page_id: pages.third.id)
          create(:condition, routing_page_id: page.id, check_page_id: pages.first.id, answer_value: nil, goto_page_id: pages.last.id)
        end

        it "renders a warning about deleting this page" do
          get delete_page_path(form_id: form.id, page_id: page.id)

          assert_select(".govuk-notification-banner", count: 1) do
            assert_select "*", "Important"
            assert_select "h3", "Question 2 is the start of a route"
            assert_select "p.govuk-body a", "Question 1’s route"
            assert_select "p.govuk-body", /Question 1’s route\s*starts at this question. If you delete this question, the route from it will also be deleted./
          end
        end
      end

      context "when page to delete is at the end of a secondary skip route" do
        let(:form) { create(:form, :ready_for_routing) }
        let(:pages) { form.pages }
        let(:page) { pages.last }

        before do
          create(:condition, routing_page_id: pages.first.id, check_page_id: pages.first.id, answer_value: "Red", goto_page_id: pages.third.id)
          create(:condition, routing_page_id: pages.second.id, check_page_id: pages.first.id, answer_value: nil, goto_page_id: pages.last.id)
        end

        it "renders a warning about deleting this page" do
          get delete_page_path(form_id: form.id, page_id: page.id)

          assert_select(".govuk-notification-banner", count: 1) do
            assert_select "*", "Important"
            assert_select "h3", "Question 5 is at the end of a route"
            assert_select "p.govuk-body a", "Question 1’s route"
            assert_select "p.govuk-body", /Question 1’s route\s*goes to this question. If you delete this question, the route to it will also be deleted./
          end
        end
      end

      context "when the multiple_branches feature is enabled", :feature_multiple_branches do
        let(:form) { create(:form, :ready_for_routing) }
        let(:pages) { form.pages }
        let(:page) { pages.first }

        context "when page to delete has no routes" do
          it "does not render a warning" do
            get delete_page_path(form_id: form.id, page_id: page.id)

            expect(response.body).not_to include "Important"
          end
        end

        context "when page to delete is the start of one route" do
          let(:page) { pages.first }

          before do
            create(:condition, routing_page_id: page.id, answer_value: "Red", goto_page_id: pages.last.id)
          end

          it "renders a warning about deleting this page" do
            get delete_page_path(form_id: form.id, page_id: page.id)

            assert_select(".govuk-notification-banner", count: 1) do
              assert_select "*", "Important"
              assert_select "h3", "Question #{page.position} has a route"
              assert_select "p.govuk-body", /If you delete this question, its route will also be deleted/
              assert_select "p.govuk-body a", "View your question routes"
            end
          end

          context "and has one exit page" do
            before do
              create(:exit_page, question_page: page)
            end

            it "renders a warning about deleting this page" do
              get delete_page_path(form_id: form.id, page_id: page.id)

              assert_select(".govuk-notification-banner", count: 1) do
                assert_select "*", "Important"
                assert_select "h3", "Question #{page.position} has a route"
                assert_select "p.govuk-body", /If you delete this question, its route and exit page will also be deleted/
                assert_select "p.govuk-body a", "View your question routes"
              end
            end
          end

          context "and has more than one exit page" do
            before do
              create(:exit_page, question_page: page)
              create(:exit_page, question_page: page)
            end

            it "renders a warning about deleting this page" do
              get delete_page_path(form_id: form.id, page_id: page.id)

              assert_select(".govuk-notification-banner", count: 1) do
                assert_select "*", "Important"
                assert_select "h3", "Question #{page.position} has a route"
                assert_select "p.govuk-body", /If you delete this question, its route and exit pages will also be deleted/
                assert_select "p.govuk-body a", "View your question routes"
              end
            end
          end
        end

        context "when page to delete is the start of mulltiple routes" do
          let(:page) { pages.first }

          before do
            create(:condition, routing_page_id: page.id, answer_value: "Red", goto_page_id: pages.last.id)
            create(:condition, routing_page_id: page.id, answer_value: "Blue", goto_page_id: pages.last.id)
          end

          it "renders a warning about deleting this page" do
            get delete_page_path(form_id: form.id, page_id: page.id)

            assert_select(".govuk-notification-banner", count: 1) do
              assert_select "*", "Important"
              assert_select "h3", "Question #{page.position} has routes"
              assert_select "p.govuk-body", /If you delete this question, its routes will also be deleted/
              assert_select "p.govuk-body a", "View your question routes"
            end
          end

          context "and has one exit page" do
            before do
              create(:exit_page, question_page: page)
            end

            it "renders a warning about deleting this page" do
              get delete_page_path(form_id: form.id, page_id: page.id)

              assert_select(".govuk-notification-banner", count: 1) do
                assert_select "*", "Important"
                assert_select "h3", "Question #{page.position} has routes"
                assert_select "p.govuk-body", /If you delete this question, its routes and exit page will also be deleted/
                assert_select "p.govuk-body a", "View your question routes"
              end
            end
          end

          context "and has more than one exit page" do
            before do
              create(:exit_page, question_page: page)
              create(:exit_page, question_page: page)
            end

            it "renders a warning about deleting this page" do
              get delete_page_path(form_id: form.id, page_id: page.id)

              assert_select(".govuk-notification-banner", count: 1) do
                assert_select "*", "Important"
                assert_select "h3", "Question #{page.position} has routes"
                assert_select "p.govuk-body", /If you delete this question, its routes and exit pages will also be deleted/
                assert_select "p.govuk-body a", "View your question routes"
              end
            end
          end
        end

        context "when page has no routes but does have one exit page" do
          let(:page) { pages.first }

          before do
            create(:exit_page, question_page: page)
          end

          it "renders a warning about deleting this page" do
            get delete_page_path(form_id: form.id, page_id: page.id)

            assert_select(".govuk-notification-banner", count: 1) do
              assert_select "*", "Important"
              assert_select "h3", "Question #{page.position} has an exit page"
              assert_select "p.govuk-body", /If you delete this question, its exit page will also be deleted/
              assert_select "p.govuk-body a", "View your question routes"
            end
          end
        end

        context "when page has no routes but does have more than one exit page" do
          let(:page) { pages.first }

          before do
            create(:exit_page, question_page: page)
            create(:exit_page, question_page: page)
          end

          it "renders a warning about deleting this page" do
            get delete_page_path(form_id: form.id, page_id: page.id)

            assert_select(".govuk-notification-banner", count: 1) do
              assert_select "*", "Important"
              assert_select "h3", "Question #{page.position} has exit pages"
              assert_select "p.govuk-body", /If you delete this question, its exit pages will also be deleted/
              assert_select "p.govuk-body a", "View your question routes"
            end
          end
        end

        context "when page to delete is the end of a route" do
          let(:page) { pages.last }

          before do
            create(:condition, routing_page_id: pages.first.id, answer_value: "Red", goto_page_id: page.id)
          end

          it "renders a warning about deleting this page" do
            get delete_page_path(form_id: form.id, page_id: page.id)

            assert_select(".govuk-notification-banner", count: 1) do
              assert_select "*", "Important"
              assert_select "h3", "There’s a route to question #{page.position}"
              assert_select "p.govuk-body", /If you delete this question, the route to it will also be deleted./
              assert_select "p.govuk-body a", "View your question routes"
            end
          end
        end

        context "when page to delete is the end of multiple routes" do
          let(:page) { pages.last }

          before do
            create(:condition, routing_page_id: pages.first.id, answer_value: "Red", goto_page_id: page.id)
            create(:condition, routing_page_id: pages.first.id, answer_value: "Blue", goto_page_id: page.id)
          end

          it "renders a warning about deleting this page" do
            get delete_page_path(form_id: form.id, page_id: page.id)

            assert_select(".govuk-notification-banner", count: 1) do
              assert_select "*", "Important"
              assert_select "h3", "There are routes to question #{page.position}"
              assert_select "p.govuk-body", /If you delete this question, the routes to it will also be deleted./
              assert_select "p.govuk-body a", "View your question routes"
            end
          end
        end

        context "when page to delete is the start and end of multiple routes" do
          let(:page) { pages.third }

          before do
            create(:condition, routing_page_id: pages.first.id, answer_value: "Red", goto_page_id: page.id)
            create(:condition, routing_page_id: page.id, answer_value: "Blue", goto_page_id: pages.last.id)
          end

          it "renders a warning about deleting this page" do
            get delete_page_path(form_id: form.id, page_id: page.id)

            assert_select(".govuk-notification-banner", count: 1) do
              assert_select "*", "Important"
              assert_select "h3", "There are routes to and from question #{page.position}"
              assert_select "p.govuk-body", /If you delete this question, its routes will also be deleted./
              assert_select "p.govuk-body a", "View your question routes"
            end
          end

          context "and has one exit page" do
            before do
              create(:exit_page, question_page: page)
            end

            it "renders a warning about deleting this page" do
              get delete_page_path(form_id: form.id, page_id: page.id)

              assert_select(".govuk-notification-banner", count: 1) do
                assert_select "*", "Important"
                assert_select "h3", "There are routes to and from question #{page.position}"
                assert_select "p.govuk-body", /If you delete this question, its routes and exit page will also be deleted/
                assert_select "p.govuk-body a", "View your question routes"
              end
            end
          end

          context "and has more than one exit page" do
            before do
              create(:exit_page, question_page: page)
              create(:exit_page, question_page: page)
            end

            it "renders a warning about deleting this page" do
              get delete_page_path(form_id: form.id, page_id: page.id)

              assert_select(".govuk-notification-banner", count: 1) do
                assert_select "*", "Important"
                assert_select "h3", "There are routes to and from question #{page.position}"
                assert_select "p.govuk-body", /If you delete this question, its routes and exit pages will also be deleted/
                assert_select "p.govuk-body a", "View your question routes"
              end
            end
          end
        end
      end
    end
  end

  describe "#destroy" do
    let(:form) { create(:form, :with_pages, pages_count: 3) }
    let(:pages) { form.pages }
    let(:page) { pages.second }

    context "with a valid page" do
      before do
        GroupForm.create!(form_id: form.id, group_id: group.id)
      end

      context "when the user has confirmed they want to delete the form" do
        before do
          delete destroy_page_path(form_id: form.id, page_id: page.id, pages_delete_confirmation_input: { confirm: "yes" })
        end

        it "redirects you to the page index screen" do
          expect(response).to redirect_to(form_pages_path)
        end

        it "displays a success flash message" do
          expect(flash[:success]).to eq "The question, ‘#{page.question_text}’, has been deleted"
        end

        it "destroys the page" do
          expect(Page.exists?(page.id)).to be false
        end

        it "updates the form document" do
          form_document_steps = form.reload.draft_form_document.content["steps"]
          expect(form_document_steps).to contain_exactly(
            hash_including(
              "id" => pages.first.external_id,
              "position" => 1,
              "next_step_id" => pages.third.external_id,
            ),
            hash_including(
              "id" => pages.third.external_id,
              "position" => 2,
              "next_step_id" => nil,
            ),
          )
        end

        include_examples "logging"

        context "when current user is not in group for form" do
          let(:membership) { nil }

          it "returns an error" do
            expect(response).to have_http_status :forbidden
          end

          it "does not destroy the form" do
            expect(Page.exists?(page.id)).to be true
          end
        end
      end

      context "when user has not confirmed whether they want to delete the question or not" do
        before do
          delete destroy_page_path(form_id: form.id, page_id: page.id, pages_delete_confirmation_input: { confirm: nil })
        end

        it "re-renders the confirm delete view with an error" do
          expect(response).to render_template(:delete)
          expect(response.body).to include "Select ‘Yes’ to delete the question"
        end

        it "does not destroy the form" do
          expect(Page.exists?(page.id)).to be true
        end
      end
    end
  end

  describe "#move_page" do
    let(:form) { create(:form, :with_pages, pages_count: 3) }
    let(:pages) { form.pages }
    let(:page) { pages.second }

    before do
      GroupForm.create!(form_id: form.id, group_id: group.id)
    end

    context "when moving the page up", :capture_logging do
      it "logs the params" do
        post move_page_path({ form_id: form.id, move_direction: { up: page.id } })
        expect(log_line["params"]).to include "move_direction" => { "up" => page.id.to_s }
      end

      it "moves the page up" do
        expect {
          post move_page_path({ form_id: form.id, move_direction: { up: page.id } })
        }.to change { page.reload.position }.from(2).to(1)
      end

      it "renders a success banner with the page's new position" do
        post move_page_path({ form_id: form.id, move_direction: { up: page.id } })
        expect(flash[:success]).to eq("‘#{pages[1].question_text}’ has moved up to number 1")
      end

      it "updates the form document" do
        post move_page_path({ form_id: form.id, move_direction: { up: page.id } })
        form_document_steps = form.reload.draft_form_document.content["steps"]
        expect(form_document_steps).to contain_exactly(
          hash_including(
            "id" => pages.second.external_id,
            "position" => 1,
            "next_step_id" => pages.first.external_id,
          ),
          hash_including(
            "id" => pages.first.external_id,
            "position" => 2,
            "next_step_id" => pages.third.external_id,
          ),
          hash_including(
            "id" => pages.third.external_id,
            "position" => 3,
            "next_step_id" => nil,
          ),
        )
      end
    end

    context "when moving the page down", :capture_logging do
      it "logs the params" do
        post move_page_path({ form_id: form.id, move_direction: { down: page.id } })
        expect(log_line["params"]).to include "move_direction" => { "down" => page.id.to_s }
      end

      it "moves the page down" do
        expect {
          post move_page_path({ form_id: form.id, move_direction: { down: page.id } })
        }.to change { page.reload.position }.from(2).to(3)
      end

      it "renders a success banner with the page's new position" do
        post move_page_path({ form_id: form.id, move_direction: { down: page.id } })
        expect(flash[:success]).to eq("‘#{pages[1].question_text}’ has moved down to number 3")
      end
    end
  end

  describe "#mark_pages_section_completed" do
    let(:form) { create(:form, :with_pages, question_section_completed: "false") }

    before do
      group.group_forms.create!(form: form)

      post form_pages_path(form.id), params: { forms_mark_pages_section_complete_input: { mark_complete: "true" } }
    end

    it "Redirects you to the form overview page" do
      expect(response).to redirect_to(form_path(form.id))
    end

    context "when the mark completed form is invalid" do
      before do
        post form_pages_path(form.id), params: { forms_mark_pages_section_complete_input: { mark_complete: nil } }
      end

      it "renders the index page" do
        expect(response).to render_template("pages/index")
      end

      it "returns 422 error code" do
        expect(response.status).to eq(422)
      end

      it "sets mark_complete to false" do
        expect(assigns[:mark_complete_input].mark_complete).to eq("false")
      end
    end
  end
end
