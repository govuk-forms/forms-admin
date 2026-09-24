require "rails_helper"

RSpec.describe WelshTranslation::SelectionOptionsComponent::View, type: :component do
  let(:table_presenter) { Forms::TranslationTablePresenter.new }

  def form_builder_for_page(form_page)
    input = Forms::WelshPageTranslationInput.new(page: form_page).assign_page_values
    form_builder_for_input(input)
  end

  def form_builder_for_input(input)
    GOVUKDesignSystemFormBuilder::FormBuilder.new(
      :forms_welsh_page_translation_input,
      input,
      ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil),
      {},
    )
  end

  context "when the page has no selection options" do
    let(:form_page) { create(:page) }

    it "renders nothing" do
      render_inline(described_class.new(page_form: form_builder_for_page(form_page), table_presenter:))
      expect(rendered_content).to be_blank
    end
  end

  context "when the page has 30 or fewer selection options" do
    let(:form_page) { create(:page, :selection_with_radios) }
    let(:option_count) { form_page.answer_settings.selection_options.size }

    before { render_inline(described_class.new(page_form: form_builder_for_page(form_page), table_presenter:)) }

    it "renders the selection options table" do
      expect(page).to have_css("table")
    end

    it "renders a text input for each option" do
      (1..option_count).each do |i|
        expect(page).to have_field("Enter Welsh option #{i}", type: "text")
      end
    end

    it "does not render a long list notice" do
      expect(page).not_to have_text(I18n.t("forms.welsh_translation.new.long_list_of_selection_options"))
    end
  end

  context "when the page has more than 30 options" do
    let(:form_page) { create(:page, :selection_with_autocomplete) }

    context "and none have Welsh translations" do
      it "renders the long list notice instead of a table" do
        render_inline(described_class.new(page_form: form_builder_for_page(form_page), table_presenter:))
        expect(page).to have_text(I18n.t("forms.welsh_translation.new.long_list_of_selection_options"))
        expect(page).not_to have_css("table")
      end
    end

    context "and all are translated without errors" do
      let(:form_page) { create(:page, :selection_with_autocomplete) }
      let(:input) do
        input = Forms::WelshPageTranslationInput.new(page: form_page).assign_page_values
        input.selection_options_cy.each_with_index { |opt, idx| opt.name_cy = "Welsh option #{idx + 1}" }
        input
      end

      before { render_inline(described_class.new(page_form: form_builder_for_input(input), table_presenter:)) }

      it "renders the translated options in a collapsible details section for Welsh" do
        expect(page).to have_css("summary", text: I18n.t("forms.welsh_translation.new.selection_options_details_summary.welsh", count: 31))
      end

      it "lists each Welsh translation in the Welsh details section" do
        within(page.find("details", text: /31 options in Welsh/)) do
          expect(page).to have_css("li", count: 31)
          expect(page).to have_css("li:first-child", text: "Welsh option 1")
          expect(page).to have_css("li:last-child", text: "Welsh option 31")
        end
      end

      it "renders the translated options in a collapsible details section for English" do
        expect(page).to have_css("summary", text: I18n.t("forms.welsh_translation.new.selection_options_details_summary.english", count: 31))
      end

      it "lists each English option in the English details section" do
        within(page.find("details", text: /31 options in English/)) do
          expect(page).to have_css("li", count: 31)
          expect(page).to have_css("li:first-child", text: "1")
          expect(page).to have_css("li:last-child", text: "31")
        end
      end

      it "renders a hidden field for each translated option's Welsh name" do
        input.selection_options_cy.each do |opt|
          expect(page).to have_css("input[type='hidden'][value='#{opt.name_cy}']", visible: :hidden)
        end
      end

      it "does not render any visible text input fields" do
        expect(page).not_to have_field(type: "text")
      end
    end

    context "and there are translations and some validation errors" do
      let(:input) { Forms::WelshPageTranslationInput.new(page: form_page).assign_page_values }

      before do
        input.selection_options_cy.first(2).each_with_index { |opt, idx| opt.name_cy = "Welsh option #{idx + 1}" }
        input.selection_options_cy[2].name_cy = "a" * 260
        input.selection_options_cy[3].name_cy = "b" * 260
        input.validate
        render_inline(described_class.new(page_form: form_builder_for_input(input), table_presenter:))
      end

      it "renders the valid translated options in a Welsh details section" do
        expect(page).to have_css("summary", text: I18n.t("forms.welsh_translation.new.selection_options_details_summary.welsh", count: 2))
      end

      it "lists only the valid Welsh translations in the Welsh details section" do
        within(page.find("details", text: /2 options in Welsh/)) do
          expect(page).to have_css("li", count: 2)
          expect(page).to have_css("li:first-child", text: "Welsh option 1")
          expect(page).to have_css("li:last-child", text: "Welsh option 2")
        end
      end

      it "renders the valid translated options in an English details section" do
        expect(page).to have_css("summary", text: I18n.t("forms.welsh_translation.new.selection_options_details_summary.english", count: 2))
      end

      it "lists only the corresponding English options in the English details section" do
        within(page.find("details", text: /2 options in English/)) do
          expect(page).to have_css("li", count: 2)
          expect(page).to have_css("li:first-child", text: "1")
          expect(page).to have_css("li:last-child", text: "2")
        end
      end

      it "renders visible input fields for the options with errors" do
        expect(page).to have_field("Enter Welsh option 3", type: "text")
        expect(page).to have_field("Enter Welsh option 4", type: "text")
      end

      it "renders hidden fields for the valid translated options" do
        input.selection_options_cy.first(2).each do |opt|
          expect(page).to have_css("input[type='hidden'][value='#{opt.name_cy}']", visible: :hidden)
        end
      end

      it "does not render visible input fields for the valid translated options" do
        option_1_field_id = input.selection_options_cy.first.form_field_id(:name_cy)
        expect(page).not_to have_field(id: option_1_field_id, type: "text")
      end
    end
  end
end
