require "rails_helper"

describe "routes/show.html.erb" do
  let(:form) { build_stubbed :form, :with_pages, pages: }
  let(:pages) { [] }
  let(:routes_input) { build(:routes_input, form:).assign_form_values }

  def render_page
    assign(:current_form, form)
    assign(:routes_input, routes_input)
    render template: "routes/show", locals: { current_form: form, routes_input: }
  end

  it "has the correct title" do
    render_page
    expect(view.content_for(:title)).to have_content("Edit question routes")
  end

  it "has the correct back link" do
    render_page
    expect(view.content_for(:back_link)).to have_link("Back to your questions", href: form_pages_path(form.id))
  end

  it "has the correct heading and caption" do
    render_page
    expect(rendered).to have_selector("h1", text: form.name)
    expect(rendered).to have_selector("h1", text: "Edit question routes")
  end

  context "when the form has pages and routes" do
    let(:pages) do
      [
        build_stubbed(
          :page,
          id: 101,
          routing_conditions: [
            build_stubbed(
              :condition,
              routing_page_id: 101,
              goto_page_id: 103,
              answer_value: nil,
            ),
          ],
        ),
        build_stubbed(:page, id: 102),
        build_stubbed(:page, id: 103),
      ]
    end

    it "has a summary list with a row for each page" do
      render_page
      expect(rendered).to have_selector(".govuk-summary-list") do |summary_list|
        expect(summary_list).to have_selector(".govuk-summary-list__row", count: pages.length)
      end
    end

    it "displays the page's position and question text" do
      render_page
      expect(rendered).to have_selector(".govuk-summary-list__key", text: pages.first.position.to_s)
      expect(rendered).to have_selector(".govuk-summary-list__value", text: pages.first.question_text)
    end

    it "includes the page's position in the id of the key" do
      render_page
      expect(rendered).to have_selector("#page-#{pages.first.position}")
    end

    it "has a select field for each page except the last one" do
      render_page
      expect(rendered).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][0][goto]"]')
      expect(rendered).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][1][goto]"]')
      expect(rendered).not_to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][2][goto]"]')
    end

    it "has options for where the route should go to for each select field" do
      render_page

      def select_options(select_field)
        select_field.find_all("option").map { [it["value"], it.text] }
      end

      expect(rendered).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][0][goto]"]') do |field|
        expect(select_options(field)).to eq [
          ["default", "2. #{pages.second.question_text}"],
          ["page_103", "3. #{pages.third.question_text}"],
          ["end_of_form", "End of the form"],
        ]
      end

      expect(rendered).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][1][goto]"]') do |field|
        expect(select_options(field)).to eq [
          ["default", "3. #{pages.third.question_text}"],
          ["end_of_form", "End of the form"],
        ]
      end
    end

    it "shows the selected goto page for the route" do
      render_page

      expect(rendered).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][0][goto]"]') do |field|
        expect(field).to have_selector("option[selected]") do |option|
          expect(option["value"]).to eq "page_103"
        end
      end

      expect(rendered).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][1][goto]"]') do |field|
        expect(field).to have_selector("option[selected]") do |option|
          expect(option["value"]).to eq "default"
        end
      end
    end

    context "when the route goes to the next page" do
      let(:pages) do
        [
          build_stubbed(
            :page,
            id: 101,
            routing_conditions: [
              build_stubbed(
                :condition,
                routing_page_id: 101,
                goto_page_id: 102,
                answer_value: nil,
              ),
            ],
          ),
          build_stubbed(:page, id: 102),
          build_stubbed(:page, id: 103),
        ]
      end

      it "shows the selected goto page for the route" do
        render_page

        expect(rendered).to have_css('.govuk-select[name="forms_routes_input[routes_attributes][0][goto]"]') do |field|
          expect(field).to have_css("option", count: 3)
          expect(field).not_to have_css("option[selected]") # if no option is has the selected attribute, the first option will be selected by default
          expect(field.first("option")["value"]).to eq "default"
        end
      end
    end

    context "when the route goes to a page before the routing page" do
      let(:pages) do
        [
          build_stubbed(:page, id: 101),
          build_stubbed(
            :page,
            id: 102,
            routing_conditions: [
              build_stubbed(
                :condition,
                routing_page_id: 102,
                goto_page_id: 101,
                answer_value: nil,
              ),
            ],
          ),
          build_stubbed(:page, id: 103),
        ]
      end

      it "shows the selected goto page for the route" do
        render_page

        expect(rendered).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][1][goto]"]') do |field|
          expect(field).to have_selector("option[selected]") do |option|
            expect(option["value"]).to eq "page_101"
          end
        end
      end

      context "when the routing page is the final page" do
        let(:pages) do
          [
            build_stubbed(:page, id: 101),
            build_stubbed(:page, id: 102),
            build_stubbed(
              :page,
              id: 103,
              routing_conditions: [
                build_stubbed(
                  :condition,
                  routing_page_id: 103,
                  goto_page_id: 101,
                  answer_value: nil,
                ),
              ],
            ),
          ]
        end

        let(:routes_input) do
          build(:routes_input, form:).assign_form_values.tap do |routes_input|
            routes_input.routes.each { |route| allow(route).to receive(:invalid?).and_return(true) }
          end
        end

        it "shows the selected goto page for the route" do
          render_page

          expect(rendered).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][2][goto]"]') do |field|
            expect(field).to have_selector("option[selected]") do |option|
              expect(option["value"]).to eq "page_101"
            end
          end
        end
      end
    end

    context "when the final page is a selection page" do
      let(:pages) do
        [
          build_stubbed(:page, id: 101),
          build_stubbed(:page, id: 102),
          build_stubbed(
            :page,
            :with_selection_settings,
            id: 103,
            routing_conditions: [
              build_stubbed(
                :condition,
                routing_page_id: 103,
                goto_page_id: 101,
                answer_value: "Option 1",
              ),
            ],
          ),
        ]
      end

      let(:routes_input) do
        build(:routes_input, form:).assign_form_values.tap do |routes_input|
          routes_input.routes.each { |route| allow(route).to receive(:invalid?).and_return(true) }
        end
      end

      it "shows the selected goto page for the route" do
        render_page

        expect(rendered).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][1][goto]"]') do |field|
          expect(field).to have_selector("option[selected]") do |option|
            expect(option["value"]).to eq "default"
          end
        end
      end

      it "has a button for adding exit pages" do
        render_page
        expect(rendered).to have_button("Add an exit page")
        expect(rendered).to have_selector("button[name='new_exit_page'][value='#{pages.last.id}']")
      end
    end

    context "when a page is a select from a list question" do
      let(:pages) do
        [
          build_stubbed(:page, :with_selection_settings, id: 101, selection_options:),
          build_stubbed(:page, id: 102),
          build_stubbed(:page, id: 103),
        ]
      end

      let(:selection_options) do
        [{ name: "Yes", value: "Yes" }, { name: "No", value: "No" }]
      end

      it "has inputs for each answer option" do
        render_page

        expect(rendered).to have_selector(".govuk-summary-list") do |summary_list|
          rows = summary_list.find_all(".govuk-summary-list__row")

          expect(rows[0]).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][0][goto]"]')
          expect(rows[0]).to have_selector('input[name="forms_routes_input[routes_attributes][0][page_id]"][value="101"]', visible: :hidden)
          expect(rows[0]).to have_selector('input[name="forms_routes_input[routes_attributes][0][answer_value]"][value="Yes"]', visible: :hidden)

          expect(rows[0]).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][1][goto]"]')
          expect(rows[0]).to have_selector('input[name="forms_routes_input[routes_attributes][1][page_id]"][value="101"]', visible: :hidden)
          expect(rows[0]).to have_selector('input[name="forms_routes_input[routes_attributes][1][answer_value]"][value="No"]', visible: :hidden)

          expect(rows[1]).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][2][goto]"]')
          expect(rows[1]).to have_selector('input[name="forms_routes_input[routes_attributes][2][page_id]"][value="102"]', visible: :hidden)

          expect(rows[2]).not_to have_selector(".govuk-select")
        end
      end

      it "has a button for adding exit pages" do
        render_page
        expect(rendered).to have_button("Add a new exit page")
        expect(rendered).to have_selector("button[name='new_exit_page'][value='#{pages.first.id}']")
      end

      context "with more than 10 options" do
        let(:selection_options) do
          (1..11).map do |i|
            { name: "Option #{i}", value: "Option #{i}" }
          end
        end

        it "has one route input for that question" do
          render_page

          expect(rendered).to have_selector(".govuk-summary-list") do |summary_list|
            rows = summary_list.find_all(".govuk-summary-list__row")

            expect(rows[0]).to have_selector(".govuk-select", count: 1)
            expect(rows[1]).to have_selector(".govuk-select", count: 1)
            expect(rows[2]).not_to have_selector(".govuk-select")
          end
        end

        it "has content explaining that routes cannot be added" do
          render_page

          expected_content = <<~TEXT
            This question has a list with more than 10 options.

            You cannot add routes from answers if the question has more than 10 options.
          TEXT

          expect(rendered).to have_selector(".govuk-summary-list") do |summary_list|
            rows = summary_list.find_all(".govuk-summary-list__row")

            expect(rows[0]).to have_text(expected_content)
            expect(rows[1]).not_to have_text(expected_content)
            expect(rows[2]).not_to have_text(expected_content)
          end
        end
      end
    end
  end

  context "when the page has an exit page" do
    let!(:pages) do
      [
        create(
          :page,
          id: 101,
        ),
        create(:page, id: 102),
        create(:page, id: 103),
      ]
    end
    let!(:exit_page) { create(:exit_page, id: 884, question_page_id: pages.first.id, heading: "Can't continue", markdown: "You can't continue") }
    let!(:another_exit_page) { create(:exit_page, id: 999, question_page_id: pages.first.id, heading: "Stop using this form", markdown: "You can't continue") }

    it "has links to the exit pages" do
      render_page
      expect(rendered).to have_selector("h2", text: "Question 1’s exit pages", normalize_ws: true)
      expect(rendered).to have_link("Exit page 1: Can't continue", href: edit_exit_page_path(form.id, pages.first.id, exit_page.id))
      expect(rendered).to have_link("Exit page 2: Stop using this form", href: edit_exit_page_path(form.id, pages.first.id, another_exit_page.id))
    end
  end

  context "when there are not enough pages" do
    let(:pages) do
      [
        build_stubbed(:page, id: 101),
      ]
    end

    it "shows a warning" do
      render_page
      expect(rendered).to have_content("You need more than one question in your form before you can add any routes.")
    end

    it "shows a link to the question pages" do
      render_page
      expect(rendered).to have_link("Back to your questions", href: form_pages_path(form.id))
    end
  end
end
