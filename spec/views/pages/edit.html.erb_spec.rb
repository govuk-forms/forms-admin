require "rails_helper"

describe "pages/edit.html.erb" do
  let(:question_text) { Faker::Lorem.question.truncate(250) }

  let(:form) { create :form, pages: [page] }
  let(:group) { create :group }
  let(:page) { create :page, question_text:, answer_type:, answer_settings: {}, page_heading: nil }
  let(:answer_type) { "email" }

  let(:draft_question) { question_input.draft_question }
  let(:question_input) do
    build :question_input,
          answer_type: page.answer_type,
          answer_settings: page.answer_settings,
          question_text: page.question_text,
          hint_text: page.hint_text
  end

  let(:current_user) { OpenStruct.new(uid: "123456") }

  before do
    # If models aren't persisted, they won't work with form builders correctly
    without_partial_double_verification do
      allow(form).to receive(:persisted?).and_return(true)
      allow(view).to receive_messages(current_form: form, draft_question:)
    end

    GroupForm.create!(group:, form_id: form.id)

    # Assign instance variables so they can be accessed from views
    assign(:page, page)
    assign(:question_input, question_input)
    assign(:current_user, current_user)

    # This is normally done in the WebController, but we aren't using
    # that in this test
    ActionView::Base.default_form_builder = GOVUKDesignSystemFormBuilder::FormBuilder

    render template: "pages/edit"
  end

  context "when given a title with characters which need escaping" do
    let(:question_text) { "Question'<> 1" }

    it "has the correct title" do
      expect(view.content_for(:title)).to have_content("Question'<> 1")
    end
  end

  context "when the page is not a selection question" do
    it "contains the optional/mandatory radio question" do
      expect(rendered).to have_text(I18n.t("helpers.legend.pages_question_input.is_optional"))
      expect(rendered).to have_text(I18n.t("helpers.label.pages_question_input.is_optional_options.true"))
      expect(rendered).to have_text(I18n.t("helpers.label.pages_question_input.is_optional_options.false"))
      expect(rendered).to have_text(I18n.t("helpers.hint.pages_question_input.is_optional_options.true"))
    end
  end

  context "when the page is a selection question" do
    let(:answer_type) { "selection" }

    it "does not contain the optional/mandatory radio question" do
      expect(rendered).not_to have_text(I18n.t("pages.is_optional.legend"))
      expect(rendered).not_to have_text(I18n.t("pages.is_optional.options.mandatory"))
      expect(rendered).not_to have_text(I18n.t("pages.is_optional.options.optional"))
      expect(rendered).not_to have_text(I18n.t("helpers.hint.pages_question_input.is_optional_options.true"))
    end
  end

  describe "routes section" do
    let(:form) { create :form, pages: [page, create(:page)] }
    let(:question_input) do
      build :question_input,
            answer_type: draft_question.answer_type,
            answer_settings: draft_question.answer_settings,
            question_text: draft_question.question_text,
            draft_question:
    end

    context "when the question is a selection question with one option only" do
      let(:draft_question) { build :selection_draft_question, only_one_option: "true" }

      it "contains the routes heading" do
        expect(rendered).to have_css("h2", text: I18n.t("pages.routes_section.heading"))
      end

      it "contains a link to the question's routes" do
        expect(rendered).to have_link("edit question routes", href: routes_path(form.id))
      end
    end

    context "when the question is a selection question with one option only and more than 10 options" do
      let(:draft_question) { build :selection_draft_question, only_one_option: "true", selection_options: (1..11).map { |i| { name: "Option #{i}", value: "option #{i}" } } }

      it "contains the text about skipping questions" do
        expect(rendered).to have_text("If you need people to skip some questions after this one, edit question routes.")
      end

      context "when the question is the last question in the form" do
        let(:form) { create :form, pages: [page] }

        it "does not contain the routes section" do
          expect(rendered).not_to have_css("h2", text: I18n.t("pages.routes_section.heading"))
        end
      end
    end

    context "when the question is a selection question with multiple options" do
      let(:draft_question) { build :selection_draft_question, only_one_option: "false" }

      it "contains the routes heading" do
        expect(rendered).to have_css("h2", text: I18n.t("pages.routes_section.heading"))
      end

      it "contains the text about skipping questions" do
        expect(rendered).to have_text("If you need people to skip some questions after this one, edit question routes.")
      end

      it "contains a link to the question's routes" do
        expect(rendered).to have_link("edit question routes", href: routes_path(form.id))
      end
    end

    context "when the question is not a selection question" do
      let(:draft_question) { build :draft_question, answer_type: "email" }

      it "contains the routes heading" do
        expect(rendered).to have_css("h2", text: I18n.t("pages.routes_section.heading"))
      end

      it "contains the text about skipping questions" do
        expect(rendered).to have_text("If you need people to skip some questions after this one, edit question routes.")
      end

      it "contains a link to the question's routes" do
        expect(rendered).to have_link("edit question routes", href: routes_path(form.id))
      end
    end

    context "when the question is not a selection question and is the last question in the form" do
      let(:form) { create :form, pages: [page] }
      let(:draft_question) { build :draft_question, answer_type: "email" }

      it "does not contain the routes section" do
        expect(rendered).not_to have_css("h2", text: I18n.t("pages.routes_section.heading"))
      end
    end
  end
end
