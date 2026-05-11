require "rails_helper"

describe "pages/selection/options.html.erb", type: :view do
  let(:form) { create :form }
  let(:page) { build :page }
  let(:page_number) { 1 }
  let(:back_link_url) { "/a-back-link-url" }
  let(:bulk_options_url) { "/a-link-to-bulk-options-page" }
  let(:selection_options_path) { "/a-path" }
  let(:selection_options) { [{ name: "France" }, { name: "Spain" }, { name: "Italy" }] }
  let(:include_none_of_the_above) { "yes" }
  let(:only_one_option) { "true" }
  let(:draft_question) { build :draft_question, answer_type: "selection", answer_settings: { only_one_option: } }

  before do
    # # mock the form.page_number method
    allow(form).to receive(:page_number).and_return(page_number)

    # # mock the path helper
    without_partial_double_verification do
      allow(view).to receive_messages(form_pages_path: "/pages", current_form: form)
    end

    # # setup instance variables
    assign(:page, page)
    assign(:selection_options_path, selection_options_path)
    assign(:back_link_url, back_link_url)
    assign(:bulk_options_url, bulk_options_url)
    assign(:selection_options_input, Pages::Selection::OptionsInput.new(selection_options:, include_none_of_the_above:, draft_question:))

    render(template: "pages/selection/options")
  end

  describe "selection options" do
    it "renders a field per existing selection option" do
      expect(rendered).to have_field(type: "text", count: 3)
      expect(rendered).to have_field(type: "text", with: "France")
      expect(rendered).to have_field(type: "text", with: "Spain")
      expect(rendered).to have_field(type: "text", with: "Italy")
    end

    it "has a remove button per option" do
      expect(rendered).to have_button("remove", count: 3)
    end

    it "has a link to the bulk options page" do
      expect(rendered).to have_link(I18n.t("selection_options.enter_all_options_into_textbox"), href: bulk_options_url)
    end

    context "when only_one_option is true for the draft question" do
      it "has paragraph text explaining that only one option can be selected" do
        expect(rendered).to have_text(I18n.t("selection_options.select_one_option"))
      end

      it "has paragraph text with a link to enter options in a text box" do
        expect(rendered).to have_link("enter all the options into one text box", href: bulk_options_url)
      end

      it "does not have hint text stating the number of options you can add" do
        expect(rendered).not_to have_text("You can add up to")
      end

      context "when there are fewer than 3000 options" do
        let(:selection_options) { (1..2999).to_a.map { |i| OpenStruct.new(name: i.to_s) } }

        it "has an add another button" do
          expect(rendered).to have_button(text: I18n.t("selection_options.add_another"))
        end

        it "does not have inset text stating you cannot add more options" do
          expect(rendered).not_to have_css(".govuk-inset-text", text: "You cannot add any more options as you have reached the maximum of 3000 options.")
        end
      end

      context "when there are 3000 options" do
        let(:selection_options) { (1..3000).to_a.map { |i| OpenStruct.new(name: i.to_s) } }

        it "does not have an add another button" do
          expect(rendered).not_to have_button(text: I18n.t("selection_options.add_another"))
        end

        it "has inset text stating you cannot add more options" do
          expect(rendered).to have_css(".govuk-inset-text", text: "You cannot add any more options as you have reached the maximum of 3000 options.")
        end
      end
    end

    context "when only_one_option is false for the draft question" do
      let(:only_one_option) { "false" }

      it "has paragraph text explaining that more than one option can be selected" do
        expect(rendered).to have_text(I18n.t("selection_options.select_more_than_one_option"))
      end

      it "has paragraph text with a link to enter options in a text box" do
        expect(rendered).to have_link("enter all the options into one text box", href: bulk_options_url)
      end

      context "when there are fewer than 30 options" do
        let(:selection_options) { (1..29).to_a.map { |i| OpenStruct.new(name: i.to_s) } }

        it "has an add another button" do
          expect(rendered).to have_button(I18n.t("selection_options.add_another"))
        end

        it "has inset text stating you cannot add more options" do
          expect(rendered).not_to have_css(".govuk-inset-text", text: "You cannot add any more options as you have reached the maximum of 30 options.")
        end
      end

      context "when there are 30 options" do
        let(:selection_options) { (1..30).to_a.map { |i| OpenStruct.new(name: i.to_s) } }

        it "does not have an add another button" do
          expect(rendered).not_to have_button(I18n.t("selection_options.add_another"))
        end

        it "has inset text stating you cannot add more options" do
          expect(rendered).to have_css(".govuk-inset-text", text: "You cannot add any more options as you have reached the maximum of 30 options.")
        end
      end
    end
  end

  describe "include none of the above radios" do
    it "contains a radio question for choosing whether to include an option for none of the above" do
      expect(rendered).to have_css("fieldset", text: I18n.t("helpers.legend.pages_selection_bulk_options_input.include_none_of_the_above"))
      expect(rendered).to have_field(I18n.t("helpers.label.pages_selection_bulk_options_input.include_none_of_the_above_options.yes"), type: "radio")
      expect(rendered).to have_field(I18n.t("helpers.label.pages_selection_bulk_options_input.include_none_of_the_above_options.yes_with_question"), type: "radio")
      expect(rendered).to have_field(I18n.t("helpers.label.pages_selection_bulk_options_input.include_none_of_the_above_options.no"), type: "radio")
    end

    context "when input object has value of yes'" do
      let(:include_none_of_the_above) { "yes" }

      it "has 'Yes' radio selected" do
        expect(rendered).to have_checked_field("pages_selection_options_input[include_none_of_the_above]", with: "yes")
        expect(rendered).to have_unchecked_field("pages_selection_options_input[include_none_of_the_above]", with: "yes_with_question")
        expect(rendered).to have_unchecked_field("pages_selection_options_input[include_none_of_the_above]", with: "no")
      end
    end

    context "when input object has value of yes_with_question" do
      let(:include_none_of_the_above) { "yes_with_question" }

      it "has 'No' radio selected" do
        expect(rendered).to have_checked_field("pages_selection_options_input[include_none_of_the_above]", with: "yes_with_question")
        expect(rendered).to have_unchecked_field("pages_selection_options_input[include_none_of_the_above]", with: "yes")
        expect(rendered).to have_unchecked_field("pages_selection_options_input[include_none_of_the_above]", with: "no")
      end
    end

    context "when input object has value of no" do
      let(:include_none_of_the_above) { "no" }

      it "has 'No' radio selected" do
        expect(rendered).to have_checked_field("pages_selection_options_input[include_none_of_the_above]", with: "no")
        expect(rendered).to have_unchecked_field("pages_selection_options_input[include_none_of_the_above]", with: "yes")
        expect(rendered).to have_unchecked_field("pages_selection_options_input[include_none_of_the_above]", with: "yes_with_question")
      end
    end

    context "when input object has no value set" do
      let(:include_none_of_the_above) { nil }

      it "does not have a radio option selected" do
        expect(rendered).to have_unchecked_field("pages_selection_options_input[include_none_of_the_above]", with: "no")
        expect(rendered).to have_unchecked_field("pages_selection_options_input[include_none_of_the_above]", with: "yes")
        expect(rendered).to have_unchecked_field("pages_selection_options_input[include_none_of_the_above]", with: "yes_with_question")
      end
    end
  end
end
