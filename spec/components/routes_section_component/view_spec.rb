require "rails_helper"

RSpec.describe RoutesSectionComponent::View, type: :component do
  include Rails.application.routes.url_helpers

  let(:question_page) { create :page }
  let(:form) { create :form, pages: [question_page, create(:page)] }
  let(:draft_question) { build :draft_question, answer_type: "email" }
  let(:question_routes_path) { routes_path(form_id: form.id, anchor: question_page.page_position_id) }

  before do
    form
    render_inline(described_class.new(page: question_page, draft_question:))
  end

  context "when the question has no routes" do
    context "when the question is a selection question with one option only" do
      let(:draft_question) { build :selection_draft_question, only_one_option: "true" }

      it "contains the routes heading" do
        expect(page).to have_css("h2", text: I18n.t("pages.routes_section.heading"))
      end

      it "contains a link to the question's routes" do
        expect(page).to have_link("edit question routes", href: question_routes_path)
      end
    end

    context "when the question is a selection question with one option only and more than 10 options" do
      let(:draft_question) { build :selection_draft_question, only_one_option: "true", selection_options: (1..11).map { |i| { name: "Option #{i}", value: "option #{i}" } } }

      it "contains the text about skipping questions" do
        expect(page).to have_text("If you need people to skip some questions after this one, edit question routes.")
      end

      context "when the question is the last question in the form" do
        let(:form) { create :form, pages: [question_page] }

        it "does not render" do
          expect(page).not_to have_css("h2", text: I18n.t("pages.routes_section.heading"))
        end
      end
    end

    context "when the question is a selection question with multiple options" do
      let(:draft_question) { build :selection_draft_question, only_one_option: "false" }

      it "contains the routes heading" do
        expect(page).to have_css("h2", text: I18n.t("pages.routes_section.heading"))
      end

      it "contains the text about skipping questions" do
        expect(page).to have_text("If you need people to skip some questions after this one, edit question routes.")
      end

      it "contains a link to the question's routes" do
        expect(page).to have_link("edit question routes", href: question_routes_path)
      end
    end

    context "when the question is not a selection question" do
      it "contains the routes heading" do
        expect(page).to have_css("h2", text: I18n.t("pages.routes_section.heading"))
      end

      it "contains the text about skipping questions" do
        expect(page).to have_text("If you need people to skip some questions after this one, edit question routes.")
      end

      it "contains a link to the question's routes" do
        expect(page).to have_link("edit question routes", href: question_routes_path)
      end
    end

    context "when the question is not a selection question and is the last question in the form" do
      let(:form) { create :form, pages: [question_page] }

      it "does not render" do
        expect(page).not_to have_css("h2", text: I18n.t("pages.routes_section.heading"))
      end
    end
  end

  context "when the question has routes" do
    let(:other_page) { create :page }
    let(:form) do
      create(:form, pages: [question_page, other_page]).tap do
        create :condition, routing_page: question_page, check_page: question_page, answer_value: "Option 1", goto_page: other_page
        question_page.reload
      end
    end
    let(:draft_question) { build :selection_draft_question, only_one_option: "true" }

    it "contains the routes heading" do
      expect(page).to have_css("h2", text: I18n.t("pages.routes_section.heading"))
    end

    it "contains the text saying the question has routes" do
      expect(page).to have_text("This question has routes: Edit question routes")
    end

    it "contains a link to the question's routes" do
      expect(page).to have_link("Edit question routes", href: question_routes_path)
    end

    context "when the question is the last question in the form" do
      let(:form) do
        create(:form, pages: [question_page]).tap do
          create :condition, routing_page: question_page, check_page: question_page, answer_value: "Option 1", skip_to_end: true
          question_page.reload
        end
      end

      it "contains the text saying the question has routes" do
        expect(page).to have_text("This question has routes: Edit question routes")
      end
    end
  end
end
