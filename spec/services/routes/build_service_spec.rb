require "rails_helper"

RSpec.describe Routes::BuildService do
  let(:form) { create(:form, pages:) }
  let(:pages) { [] }
  let(:service) { described_class.new(form:) }

  describe "#build_routes" do
    context "when the form has no pages" do
      it "returns an empty array" do
        expect(service.build_routes).to be_empty
      end
    end

    context "when the form has pages" do
      let(:pages) do
        create_list(:page, 3) do |page, i|
          page.id = i + 1
          page.position = i + 1
          page.question_text = "Page #{i + 1}"
        end
      end

      context "with a generic (non-selection) page" do
        it "builds a single route input for each page" do
          routes = service.build_routes
          expect(routes.length).to eq(3)

          route_for_page1 = routes.first
          expect(route_for_page1).to be_a(Forms::RouteInput)
          expect(route_for_page1.page_id).to eq(pages.first.id)
        end

        it "sets the goto value to default by default" do
          route_for_page1 = service.build_routes.first
          expect(route_for_page1.goto).to eq(GotoValue::DefaultValue.new)
        end

        context "when a condition exists for the generic page" do
          let!(:conditions) do
            [
              create(:condition, form:, routing_page: pages.first, goto_page_id: pages.third.id, answer_value: nil),
            ]
          end

          it "sets the condition ID on the route input" do
            route_for_page1 = service.build_routes.first
            expect(route_for_page1.id).to eq(conditions.first.id)
          end

          it "sets the goto value to the condition's goto_page_id" do
            route_for_page1 = service.build_routes.first
            expect(route_for_page1.goto).to eq(GotoValue::Page.new(pages.third.id))
          end
        end

        context "when a condition exists to skip to the end" do
          before do
            create(:condition, form:, routing_page: pages.first, skip_to_end: true, answer_value: nil)
          end

          it "sets the goto value to 'check_your_answers'" do
            route_for_page1 = service.build_routes.first
            expect(route_for_page1.goto).to eq(GotoValue::EndOfFormValue.new)
          end
        end

        context "when a condition goes to the next page" do
          before do
            create(:condition, form:, routing_page: pages.first, goto_page: pages.second, answer_value: nil)
          end

          it "sets the goto value to the next page ID" do
            route_for_page1 = service.build_routes.first
            expect(route_for_page1.goto).to eq(GotoValue::Page.new(pages.second.id))
          end

          it "has a goto option for each page after" do
            route_for_page1 = service.build_routes.first
            expect(route_for_page1.goto_options.length).to eq 3
          end
        end
      end

      context "with a selection page (radios)" do
        let(:selection_options) { [{ "name" => "Yes", "value" => "Yes" }, { "name" => "No", "value" => "No" }] }
        let!(:pages) do
          [
            create(:page, :with_selection_settings, id: 1, position: 1, selection_options:),
            create(:page, id: 2, position: 2),
            create(:page, id: 3, position: 3),
          ]
        end

        it "builds a route input for each option on the selection page" do
          routes = service.build_routes
          expect(routes.length).to eq(4) # 2 for page 1 options, 1 for page 2, 1 for page 3

          routes_for_page1 = routes.select { |r| r.page_id == pages.first.id }
          expect(routes_for_page1.length).to eq(2) # 'Yes' and 'No' options

          route_for_yes = routes_for_page1.find { |r| r.answer_value == "Yes" }
          route_for_no = routes_for_page1.find { |r| r.answer_value == "No" }

          expect(route_for_yes).not_to be_nil
          expect(route_for_no).not_to be_nil
        end

        context "when the selection page has more than 10 options" do
          let(:selection_options) do
            (1..11).map do |i|
              { name: "Option #{i}", value: "Option #{i}" }
            end
          end

          it "builds a single route input for the selection page" do
            routes = service.build_routes

            expect(routes.length).to eq(3)
            expect(routes).to all be_a(Forms::RouteInput)
            expect(routes.filter { it.page_id == pages.first.id }.length).to eq(1)
          end
        end

        context "when the selection page is optional" do
          let(:pages) do
            [
              create(:page, :selection_with_none_of_the_above_question, id: 1, position: 1),
              create(:page, id: 2, position: 2),
              create(:page, id: 3, position: 3),
            ]
          end

          it "includes a 'None of the above' option" do
            routes_for_page1 = service.build_routes.select { |r| r.page_id == pages.first.id }
            expect(routes_for_page1.length).to eq(3) # 'Yes', 'No', and 'None of the above'

            none_of_the_above_route = routes_for_page1.find { |r| r.answer_value == "none_of_the_above" }
            expect(none_of_the_above_route).not_to be_nil
            expect(none_of_the_above_route.label[:text]).to eq("If option 3 (None of the above), go to:")
          end
        end

        context "with conditions for selection options" do
          let!(:conditions) do
            [
              create(:condition, routing_page_id: pages.first.id, answer_value: "Yes", goto_page_id: pages.third.id),
              create(:condition, routing_page_id: pages.first.id, answer_value: "No", skip_to_end: true),
            ]
          end

          it "assigns the correct goto values based on the conditions" do
            routes_for_page1 = service.build_routes.select { |r| r.page_id == pages.first.id }
            route_for_yes = routes_for_page1.find { |r| r.answer_value == "Yes" }
            route_for_no = routes_for_page1.find { |r| r.answer_value == "No" }

            expect(route_for_yes.goto).to eq(GotoValue::Page.new(pages.third.id))
            expect(route_for_no.goto).to eq(GotoValue::EndOfFormValue.new)
          end

          it "assigns correct condition IDs" do
            routes_for_page1 = service.build_routes.select { |r| r.page_id == pages.first.id }
            condition_for_yes = conditions.find { |c| c.answer_value == "Yes" }
            condition_for_no = conditions.find { |c| c.answer_value == "No" }

            route_for_yes = routes_for_page1.find { |r| r.answer_value == "Yes" }
            route_for_no = routes_for_page1.find { |r| r.answer_value == "No" }

            expect(route_for_yes.id).to eq(condition_for_yes.id)
            expect(route_for_no.id).to eq(condition_for_no.id)
          end
        end

        context "with exit page conditions" do
          let!(:conditions) do
            [
              create(:condition, form:, routing_page: pages.first, exit_page_id: exit_page.id, answer_value: "Yes"),
            ]
          end
          let(:exit_page) { create(:exit_page, heading: "exit", markdown: "asjdkla") }

          it "assigns the correct goto values based on the conditions" do
            routes_for_page1 = service.build_routes.select { |r| r.page_id == pages.first.id }
            route_for_yes = routes_for_page1.find { |r| r.answer_value == "Yes" }

            expect(routes_for_page1.length).to eq(2)
            expect(route_for_yes.goto).to eq(GotoValue::ExitPage.new(exit_page.id))
          end

          it "assigns correct condition IDs" do
            routes_for_page1 = service.build_routes.select { |r| r.page_id == pages.first.id }
            condition_for_yes = conditions.find { |c| c.answer_value == "Yes" }

            route_for_yes = routes_for_page1.find { |r| r.answer_value == "Yes" }

            expect(route_for_yes.id).to eq(condition_for_yes.id)
          end
        end
      end

      context "with a selection page (checkboxes)" do
        let(:pages) do
          [
            create(:page, :with_selection_settings, id: 1, position: 1, answer_settings: { only_one_option: "false" }),
            create(:page, id: 2, position: 2),
          ]
        end

        it "treats it as a generic page and builds one route" do
          # Checkbox pages (only_one_option == "false") do not support answer-level routing,
          # so they should be treated like generic pages.
          routes = service.build_routes
          expect(routes.length).to eq(2) # One for page 1, one for page 2

          route_for_page1 = routes.first
          expect(route_for_page1).to be_a(Forms::RouteInput)
          expect(route_for_page1.page_id).to eq(pages.first.id)
          expect(route_for_page1.answer_value).to be_nil
          expect(route_for_page1.label).to eq({ text: "After question #{pages.first.position}, go to:" })
        end
      end
    end
  end

  describe "#options_for_goto_page" do
    let(:pages) do
      create_list(:page, 3) do |page, i|
        page.id = 101 + i
        page.position = i + 1
        page.question_text = "question #{i + 1}"
      end
    end

    context "when the page has no next page" do
      it "returns the end of the form option" do
        expected_options = [["End of the form", GotoValue::DefaultValue.new]]

        expect(service.options_for_goto_page(pages.third)).to match_array(expected_options)
      end

      context "when there is a selected page" do
        it "returns the selected page and end of the form options" do
          expected_options = [
            ["1. question 1", GotoValue::Page.new(pages.first.id)],
            ["End of the form", GotoValue::DefaultValue.new],
          ]

          expect(service.options_for_goto_page(pages.third, GotoValue::Page.new(pages.first.id))).to match_array(expected_options)
        end
      end

      context "when the page has exit pages" do
        let(:pages) do
          create_list(:page, 3) do |page, i|
            page.position = i + 1
            page.question_text = "question #{i + 1}"
          end
        end
        let!(:exit_page) { create(:exit_page, question_page: pages.third, heading: "Sorry, you cannot use this service") }

        it "includes the exit pages in the options" do
          expected_options = [
            ["Exit page 1: Sorry, you cannot use this service", GotoValue::ExitPage.new(exit_page.id)],
            ["End of the form", GotoValue::DefaultValue.new],
          ]

          expect(service.options_for_goto_page(pages.third)).to match_array(expected_options)
        end
      end

      context "when the selected value is not a page (e.g. an exit page)" do
        it "does not raise an error" do
          expect { service.options_for_goto_page(pages.third, GotoValue::ExitPage.new(999)) }.not_to raise_error
        end
      end
    end

    it "returns a list of all possible goto options" do
      options = service.options_for_goto_page(pages.first)

      expected_other_options = [
        ["3. question 3", GotoValue::Page.new(pages.third.id)],
        ["End of the form", GotoValue::EndOfFormValue.new],
      ]

      all_other_options = options.reject { |opt| opt[1] == GotoValue::DefaultValue.new }

      expect(all_other_options).to match_array(expected_other_options)
    end

    it "replaces the next page with the default option" do
      options = service.options_for_goto_page(pages.first)
      default_option = options.find { |opt| opt[1] == GotoValue::DefaultValue.new }

      expect(default_option).to eq(["2. #{pages.second.question_text}", GotoValue::DefaultValue.new])
    end

    it "does not include the current page in the options" do
      options = service.options_for_goto_page(pages.first)
      page_ids = options.map { it.second.respond_to?(:page_id) && it.second.page_id }

      expect(page_ids).not_to include(pages.first.id)
    end

    it "does not include pages before the current page in the options" do
      options = service.options_for_goto_page(pages.second)

      expect(options).to eq [
        ["3. #{pages.third.question_text}", GotoValue::DefaultValue.new],
        ["End of the form", GotoValue::EndOfFormValue.new],
      ]
    end

    context "when there is a selected goto page and the goto page is before the current page" do
      it "includes the goto page in the options" do
        options = service.options_for_goto_page(pages.second, GotoValue::Page.new(pages.first.id))

        expect(options).to eq [
          ["1. #{pages.first.question_text}", GotoValue::Page.new(pages.first.id)],
          ["3. #{pages.third.question_text}", GotoValue::DefaultValue.new],
          ["End of the form", GotoValue::EndOfFormValue.new],
        ]
      end
    end
  end
end
