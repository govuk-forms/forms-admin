require "rails_helper"

describe "pages/routes/show.html.erb" do
  let(:form) { create :form, :ready_for_routing }
  let(:pages) { form.pages }
  let(:page) { pages.first }
  let(:routes) { page.check_conditions }
  let(:errors) { [] }

  let(:route_cards) do
    [
      {
        card: { title: "route 1" },
        rows: [
          { key: { text: "route 1 key" }, value: { text: "route 1 value" } },
        ],
      },
    ]
  end

  let(:route_summary_card_data_service) { instance_double(RouteSummaryCardDataPresenter, summary_card_data: route_cards, errors:, routes:, next_page: pages.second, pages:, page:, form:) }

  before do
    allow(form).to receive(:group).and_return(build(:group))
  end

  context "when there are no routes" do
    before do
      render template: "pages/routes/show", locals: { current_form: form, page:, route_summary_card_data_presenter: route_summary_card_data_service }
    end

    it "has the correct title" do
      expect(view.content_for(:title)).to have_content("Question 1’s routes")
    end

    it "has the correct back link" do
      expect(view.content_for(:back_link)).to have_link(I18n.t("back_link.form_pages"), href: form_pages_path(form.id))
    end

    it "has the correct heading and caption" do
      expect(rendered).to have_selector("h1", text: form.name)
      expect(rendered).to have_selector("h1", text: I18n.t("page_titles.routes_show", question_number: page.position))
    end

    it "shows the page title as a summary list" do
      expect(rendered).to have_css(".govuk-summary-list__key", text: "Question #{page.position}")
      expect(rendered).to have_css(".govuk-summary-list__value", text: page.question_text)
    end

    it "shows the correct route cards" do
      expect(rendered).to have_css(".govuk-summary-list__key", text: "route 1 key")
      expect(rendered).to have_css(".govuk-summary-list__value", text: "route 1 value")
    end

    it "has a back to questions link" do
      expect(rendered).to have_link(I18n.t("pages.back_to_your_questions"), href: form_pages_path(form.id))
    end

    it "does not have a link to delete all routes" do
      expect(rendered).not_to have_link(I18n.t("page_route_card.delete_route"), href: delete_routes_path(form.id, page.id))
    end
  end

  context "when the page has a single route" do
    let(:route_summary_card_data_service) { RouteSummaryCardDataPresenter.new form:, page: }

    before do
      create :condition, routing_page_id: pages.first.id, check_page_id: pages.first.id, answer_value: "Option 1", goto_page_id: pages.third.id
      pages.each(&:reload)

      render template: "pages/routes/show", locals: { current_form: form, page:, route_summary_card_data_presenter: route_summary_card_data_service }
    end

    it "does not have a link to delete all routes" do
      expect(rendered).not_to have_link(I18n.t("page_route_card.delete_route"), href: delete_routes_path(form.id, page.id))
    end

    it "has an any other answer section" do
      expect(rendered).to have_css "h2.govuk-heading-m", text: "If people select any other answer"
    end

    it "has a link to set questions to skip" do
      expect(rendered).to have_link(
        "Set questions to skip",
        class: "govuk-button--secondary",
        href: new_secondary_skip_path(form.id, page.id),
      )
    end

    describe "any other answer section" do
      it "shows the number of the next question in the form" do
        expect(rendered).to have_text "People who select any other answer will continue to question #{pages.second.position} and through the rest of the form"
      end

      context "when the page is the last question" do
        let(:page) { pages.last }

        before do
          create :condition, routing_page_id: pages.last.id, check_page_id: pages.last.id, answer_value: "Option 1", goto_page_id: nil, skip_to_end: true
          pages.each(&:reload)
        end

        it "shows the check your answers page as the next question in the form" do
          expect(rendered).to have_text "People who select any other answer will continue to the end of the form."
        end

        it "does not have a link to set questions to skip" do
          expect(rendered).not_to have_link(
            "Set questions to skip",
            class: "govuk-button--secondary",
            href: new_secondary_skip_path(form.id, page.id),
          )
        end
      end
    end
  end

  context "when the page has a route that leads to an exit page" do
    before do
      create :condition, :with_exit_page, routing_page_id: page.id, check_page_id: page.id, answer_value: "Option 1"
      pages.each(&:reload)

      render template: "pages/routes/show", locals: { current_form: form, page:, route_summary_card_data_presenter: route_summary_card_data_service }
    end

    it "does not show the link to set questions to skip" do
      expect(rendered).not_to have_link(
        "Set questions to skip",
        class: "govuk-button--secondary",
        href: new_secondary_skip_path(form.id, page.id),
      )
    end
  end

  context "when the page has a skip and a secondary skip" do
    let(:route_summary_card_data_service) { RouteSummaryCardDataPresenter.new form:, page: }

    before do
      create :condition, routing_page_id: pages.first.id, check_page_id: pages.first.id, answer_value: "Option 1", goto_page_id: pages.third.id
      create :condition, routing_page_id: pages.second.id, check_page_id: pages.first.id, goto_page_id: pages.fourth.id
      pages.each(&:reload)

      render template: "pages/routes/show", locals: { current_form: form, page:, route_summary_card_data_presenter: route_summary_card_data_service }
    end

    it "has a link to delete all routes" do
      expect(rendered).to have_link(I18n.t("page_route_card.delete_route"), href: delete_routes_path(form.id, page.id))
    end

    it "does not have an any other answer section" do
      expect(rendered).not_to have_css "h2", text: "Any other answer"
      expect(rendered).not_to have_link "Set questions to skip"
    end
  end

  context "when there is an error" do
    let(:errors) { [OpenStruct.new(link: "goto-1", message: "Error text")] }

    before do
      render template: "pages/routes/show", locals: { current_form: form, page:, route_summary_card_data_presenter: route_summary_card_data_service }
    end

    it "shows the error message" do
      expect(rendered).to have_text("Error text")
    end
  end
end
