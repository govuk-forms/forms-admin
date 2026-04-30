require "rails_helper"

RSpec.describe PageListComponent::View, type: :component do
  let(:form) { create :form, :with_group }
  let(:pages) { form.reload.pages }
  let(:page_list_component) { described_class.new(pages:, form:) }

  describe "rendering component" do
    context "when there are no pages" do
      before do
        render_inline(page_list_component)
      end

      it "is blank" do
        expect(page).not_to have_selector("*")
      end
    end

    context "when the form has a single page" do
      let!(:single_page) { create :page, form: }

      before do
        render_inline(page_list_component)
      end

      it "renders the question number" do
        expect(page).to have_css("dt.govuk-summary-list__key", text: single_page.position.to_s)
      end

      it "renders question title" do
        expect(page).to have_content(single_page.question_text.to_s)
      end

      it "renders link" do
        expect(page).to have_link("Edit")
      end

      it "does not have re-ordering buttons" do
        expect(page).not_to have_button("Move up")
        expect(page).not_to have_button("Move down")
      end

      it "includes the page id in the id for the row" do
        expect(page).to have_css "#page_#{single_page.id}.govuk-summary-list__row"
      end
    end

    context "when the form has multiple pages" do
      let(:form) { create :form, :with_pages, :with_group }
      let(:first_page) { form.pages.first }
      let(:second_page) { form.pages.second }

      context "when there are no conditions" do
        before do
          render_inline(page_list_component)
        end

        it "renders the question numbers" do
          expect(page).to have_css("dt.govuk-summary-list__key", text: first_page.position)
          expect(page).to have_css("dt.govuk-summary-list__key", text: second_page.position)
        end

        it "renders a move up link" do
          expect(page).to have_button("Move up")
        end

        it "renders a move down link" do
          expect(page).to have_button("Move down")
        end

        it "includes the page id in the id for each row" do
          expect(page).to have_css "#page_#{first_page.id}.govuk-summary-list__row"
          expect(page).to have_css "#page_#{second_page.id}.govuk-summary-list__row"
        end

        it "conditions section is not present" do
          expect(page).to have_css(".govuk-summary-list__row", count: pages.length)
        end
      end

      context "when the form has conditions" do
        let(:form) { create :form, :ready_for_routing, :with_group }
        let(:edit_condition_path) { "/forms/0/pages/1/conditions/1" }

        context "when the page has a single condition" do
          let!(:condition) { create :condition, routing_page_id: pages.first.id, check_page_id: pages.first.id, answer_value: "Option 1", goto_page_id: pages.third.id }

          before do
            render_inline(page_list_component)
          end

          it "does not render any errors" do
            expect(page).not_to have_css(".app-page_list__route-text--error")
          end

          it "renders the condition description" do
            condition_description = "If “#{pages.first.question_text}” is answered as “#{condition.answer_value}” go to #{pages.third.position}, “#{pages.third.question_text}”"

            expect(page).to have_css("dd.govuk-summary-list__value", text: condition_description)
          end

          it "renders the routing details" do
            condition_answer_value_text = I18n.t("page_conditions.condition_answer_value_text", answer_value: condition.answer_value)
            condition_goto_page_text = I18n.t("page_conditions.condition_goto_page_text", goto_page_question_number: pages.third.position, goto_page_question_text: pages.third.question_text)
            expect(page).to have_css("dd.govuk-summary-list__value", text: condition_answer_value_text)
            expect(page).to have_css("dd.govuk-summary-list__value", text: condition_goto_page_text)
          end

          it "renders link" do
            expect(page).to have_link("Edit")
          end
        end

        context "when the condition has an exit page heading" do
          let!(:condition) { create :condition, :with_exit_page, routing_page_id: pages.first.id, check_page_id: pages.first.id, answer_value: "Option 1" }

          before do
            render_inline(page_list_component)
          end

          it "renders the condition description" do
            expect(page).to have_css("dd.govuk-summary-list__value", text: "If “#{pages.first.question_text}” is answered as “#{condition.answer_value}” go to exit page, “#{condition.exit_page_heading}”")
          end
        end

        context "when the page has a condition with multiple errors" do
          before do
            create :condition, routing_page_id: pages.first.id, check_page_id: pages.first.id, answer_value: nil, goto_page_id: nil

            render_inline(page_list_component)
          end

          it "renders the errors in an unordered list" do
            condition_answer_value_error = I18n.t("errors.page_conditions.answer_value_doesnt_exist", question_number: pages.first.position, route_number: 1)
            condition_goto_page_error = I18n.t("errors.page_conditions.goto_page_doesnt_exist", question_number: pages.first.position, route_number: 1)
            expect(page).to have_css("ul > li", text: condition_answer_value_error)
            expect(page).to have_css("ul > li", text: condition_goto_page_error)
          end

          it "renders link" do
            expect(page).to have_link("Edit")
          end
        end
      end

      context "when the form has a valid branch route" do
        let(:form) { create :form, :ready_for_routing, :with_group }
        let!(:secondary_skip_condition) { create :condition, routing_page_id: pages.second.id, check_page_id: pages.first.id, answer_value: nil, goto_page_id: pages.fourth.id }

        before do
          create :condition, routing_page_id: pages.first.id, check_page_id: pages.first.id, answer_value: "Option 1", goto_page_id: pages.third.id
          pages.each(&:reload)

          render_inline(page_list_component)
        end

        it "renders a summary list row for the any other answer route" do
          expect(page).to have_css("#condition_#{secondary_skip_condition.id}.govuk-summary-list__row", text: "Question #{pages.first.position}’s routes") do |summary_list_row|
            expect(summary_list_row).to have_link(href: show_routes_path(form_id: form.id, page_id: pages.first.id)) do |link|
              expect(link).to have_content("Edit Question #{pages.first.position}’s routes")
            end
          end
        end
      end

      context "when the form has a branch route with an error" do
        let(:form) { create :form, :ready_for_routing, :with_group }

        before do
          create :condition, routing_page_id: pages.first.id, check_page_id: pages.first.id, answer_value: "Option 1", goto_page_id: pages.third.id
          create :condition, routing_page_id: pages.second.id, check_page_id: pages.first.id, answer_value: nil, goto_page_id: pages.third.id
          pages.each(&:reload)

          render_inline(page_list_component)
        end

        it "renders an error message" do
          error_message = I18n.t("errors.page_conditions.cannot_route_to_next_page", question_number: pages.first.position, route_number: "for any other answer")
          expect(page).to have_css ".app-page_list__route-text--error", text: error_message
        end
      end
    end
  end

  describe "class methods" do
    let(:form) { create :form, :with_pages, :with_group }

    describe "show_up_button" do
      it "returns false when index is 0" do
        expect(page_list_component.show_up_button(0)).to be false
      end

      it "returns true when index is not 0" do
        expect(page_list_component.show_up_button(1)).to be true
      end
    end

    describe "show_down_button" do
      it "returns false for the last page in the list" do
        expect(page_list_component.show_down_button(pages.length - 1)).to be false
      end

      it "returns true for other pages" do
        expect(page_list_component.show_down_button(pages.length - 2)).to be true
      end
    end

    describe "#page_row_id" do
      it "returns the corrrect id text for a given page" do
        expect(page_list_component.page_row_id(pages.second)).to eq "page_#{pages.second.id}"
      end
    end

    describe "error_id" do
      it "returns the corrrect id text for a given condition number" do
        expect(PageListComponent::ErrorSummary::View.error_id(1)).to eq "condition_1"
      end
    end

    describe "#condition_description" do
      context "when condition has all values set" do
        let(:condition) do
          create(
            :condition,
            routing_page_id: pages.first.id,
            check_page_id: pages.first.id,
            answer_value: "Option 1",
            goto_page_id: pages.third.id,
          )
        end

        it "returns complete condition description" do
          expected_text = "If “#{pages.first.question_text}” is answered as “#{condition.answer_value}” go to #{pages.third.position}, “#{pages.third.question_text}”"
          expect(page_list_component.condition_description(condition)).to eq(expected_text)
        end
      end

      context "when answer value is 'none_of_the_above'" do
        let(:condition) do
          create(
            :condition,
            routing_page_id: pages.first.id,
            check_page_id: pages.first.id,
            answer_value: "none_of_the_above",
            goto_page_id: pages.third.id,
          )
        end

        it "returns description with 'None of the above' text" do
          expected_text = "If “#{pages.first.question_text}” is answered as “None of the above” go to #{pages.third.position}, “#{pages.third.question_text}”"
          expect(page_list_component.condition_description(condition)).to eq(expected_text)
        end
      end

      context "when answer value is missing" do
        let(:condition) do
          create(
            :condition,
            routing_page_id: pages.first.id,
            check_page_id: pages.first.id,
            answer_value: nil,
            goto_page_id: pages.third.id,
          )
        end

        it "returns description with error text for missing answer" do
          expected_text = "If “#{pages.first.question_text}” is answered as [Answer not selected] go to #{pages.third.position}, “#{pages.third.question_text}”"
          expect(page_list_component.condition_description(condition)).to eq(expected_text)
        end
      end

      context "when skip_to_end is true" do
        let(:condition) do
          create(
            :condition,
            routing_page_id: pages.first.id,
            check_page_id: pages.first.id,
            answer_value: "Option 1",
            goto_page_id: nil,
            skip_to_end: true,
          )
        end

        it "returns description with 'Check your answers' text" do
          expected_text = "If “#{pages.first.question_text}” is answered as “#{condition.answer_value}” go to end of form."
          expect(page_list_component.condition_description(condition)).to eq(expected_text)
        end
      end

      context "when goto page is missing and skip_to_end is false" do
        let(:condition) do
          create(
            :condition,
            routing_page_id: pages.first.id,
            check_page_id: pages.first.id,
            answer_value: "Option 1",
            goto_page_id: nil,
            skip_to_end: false,
          )
        end

        it "returns description with error text for missing goto page" do
          expected_text = "If “#{pages.first.question_text}” is answered as “#{condition.answer_value}” go to [Question not selected]"
          expect(page_list_component.condition_description(condition)).to eq(expected_text)
        end
      end

      context "when showing a secondary_skip" do
        let(:condition) do
          create(
            :condition,
            routing_page_id: pages.second.id,
            check_page_id: pages.first.id,
            answer_value: nil,
            goto_page_id: pages.fourth.id,
          )
        end

        it "returns correct description" do
          expected_text = "After #{pages.second.position}, “#{pages.second.question_text}” go to #{pages.fourth.position}, “#{pages.fourth.question_text}”"
          expect(page_list_component.condition_description(condition)).to eq(expected_text)
        end
      end
    end

    describe "#branch_condition_description" do
      context "when condition has all values set" do
        let(:condition) do
          create(
            :condition,
            routing_page_id: pages.first.id,
            check_page_id: pages.first.id,
            answer_value: "Option 1",
            goto_page_id: pages.third.id,
          )
        end

        it "returns complete condition description" do
          expected_text = "“#{condition.answer_value}” go to #{pages.third.position}, “#{pages.third.question_text}”"
          expect(page_list_component.branch_condition_description(condition)).to eq(expected_text)
        end
      end

      context "when answer value is 'none_of_the_above'" do
        let(:condition) do
          create(
            :condition,
            routing_page_id: pages.first.id,
            check_page_id: pages.first.id,
            answer_value: "none_of_the_above",
            goto_page_id: pages.third.id,
          )
        end

        it "returns description with 'None of the above' text" do
          expected_text = "“None of the above” go to #{pages.third.position}, “#{pages.third.question_text}”"
          expect(page_list_component.branch_condition_description(condition)).to eq(expected_text)
        end
      end

      context "when skip_to_end is true" do
        let(:condition) do
          create(
            :condition,
            routing_page_id: pages.first.id,
            check_page_id: pages.first.id,
            answer_value: "Option 1",
            goto_page_id: nil,
            skip_to_end: true,
          )
        end

        it "returns description with 'Check your answers' text" do
          expected_text = "“#{condition.answer_value}” go to end of form."
          expect(page_list_component.branch_condition_description(condition)).to eq(expected_text)
        end
      end

      context "when showing an unconditional route" do
        let(:condition) do
          create(
            :condition,
            routing_page_id: pages.second.id,
            check_page_id: pages.first.id,
            answer_value: nil,
            goto_page_id: pages.fourth.id,
          )
        end

        it "returns correct description" do
          expected_text = "Go to #{pages.fourth.position}, “#{pages.fourth.question_text}”"
          expect(page_list_component.branch_condition_description(condition)).to eq(expected_text)
        end
      end
    end
  end
end
