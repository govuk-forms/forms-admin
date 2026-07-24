require "rails_helper"

RSpec.describe Forms::WelshSelectionOptionTranslationInput, type: :model do
  subject(:welsh_selection_option_translation_input) { described_class.new(new_input_data) }

  let(:page) { build :page, :with_selection_settings, id: 747 }
  let(:selection_option_cy) { DataStruct.new(name: "Option 1", value: page.answer_settings.selection_options.first["value"]) }

  let(:new_input_data) do
    {
      selection_option: selection_option_cy,
      page:,
      id: "1",
      name_cy: "Other name",
    }
  end

  describe "id" do
    it "converts the id to an integer" do
      expect(welsh_selection_option_translation_input.id).to eq(1)
    end
  end

  describe "#assign_selection_option_values" do
    it "assigns the selection option name" do
      welsh_selection_option_translation_input.assign_selection_option_values
      expect(welsh_selection_option_translation_input.name_cy).to eq(selection_option_cy["name"])
    end

    it "does not assign the selection option name if the selection option is nil" do
      welsh_selection_option_translation_input.selection_option = nil
      welsh_selection_option_translation_input.assign_selection_option_values
      expect(welsh_selection_option_translation_input.name_cy).to eq("Other name")
    end
  end

  describe "#as_selection_option" do
    it "returns a hash with the selection option name and value" do
      welsh_selection_option_translation_input.assign_selection_option_values
      expect(welsh_selection_option_translation_input.as_selection_option).to eq(name: selection_option_cy["name"], value: selection_option_cy["value"])
    end
  end

  describe "#form_field_id" do
    it "returns the custom ID for each attribute" do
      expect(welsh_selection_option_translation_input.form_field_id(:name_cy)).to eq "forms_welsh_selection_option_translation_input_747_selection_options_cy_1_name_cy"
    end
  end

  describe "#selection_number" do
    it "returns the id add one" do
      expect(welsh_selection_option_translation_input.selection_number).to eq(2)
    end
  end

  describe "#question_number" do
    it "returns the page position" do
      expect(welsh_selection_option_translation_input.question_number).to eq(page.position)
    end
  end

  describe "validations" do
    context "when the translation is not marked complete" do
      context "when the name_cy is blank" do
        let(:new_input_data) { super().merge(name_cy: "") }

        it "is valid" do
          expect(welsh_selection_option_translation_input).to be_valid
          expect(welsh_selection_option_translation_input.errors.full_messages_for(:name_cy)).to be_empty
        end
      end

      context "when the name_cy is 251 characters or more" do
        let(:new_input_data) { super().merge(name_cy: "a" * 251) }

        it "is invalid when name_cy is over 250 characters" do
          expect(welsh_selection_option_translation_input).not_to be_valid
          expected_error_message = "Name cy #{I18n.t('activemodel.errors.models.forms/welsh_selection_option_translation_input.attributes.name_cy.too_long', selection_number: 2, question_number: page.position, count: 250)}"
          expect(welsh_selection_option_translation_input.errors.full_messages_for(:name_cy)).to include(expected_error_message)
        end
      end
    end

    context "when the translation is marked complete" do
      context "when the name_cy is blank" do
        let(:new_input_data) { super().merge(name_cy: "") }

        it "is invalid" do
          expect(welsh_selection_option_translation_input).not_to be_valid(:mark_complete)
          expected_error_message = "Name cy #{I18n.t('activemodel.errors.models.forms/welsh_selection_option_translation_input.attributes.name_cy.blank', selection_number: 2, question_number: page.position)}"
          expect(welsh_selection_option_translation_input.errors.full_messages_for(:name_cy)).to include(expected_error_message)
        end
      end
    end
  end

  describe "#all_fields_empty?" do
    it "returns false when fields are not empty" do
      expect(welsh_selection_option_translation_input.all_fields_empty?).to be false
    end

    context "when the welsh selection option fields are all empty" do
      let(:new_input_data) { { selection_option: selection_option_cy, page:, id: "1", name_cy: "" } }

      it "returns true" do
        expect(welsh_selection_option_translation_input.all_fields_empty?).to be true
      end
    end
  end

  describe "#show_name_input?" do
    context "when the page has 30 or fewer selection options" do
      it "shows the input regardless of whether the name has a value" do
        expect(welsh_selection_option_translation_input.show_name_input?).to be true
      end
    end

    context "when the page has more than 30 selection options" do
      let(:page) { build(:page, :selection_with_autocomplete, id: 747) }
      let(:selection_option_cy) { DataStruct.new(name: "Option 1", value: page.answer_settings.selection_options.first["value"]) }

      context "when the selection option already has a Welsh value" do
        let(:new_input_data) { super().merge(name_cy: "Welsh option") }

        it "hides the input" do
          expect(welsh_selection_option_translation_input.show_name_input?).to be false
        end
      end

      context "when the selection option does not have a Welsh value" do
        let(:new_input_data) { super().merge(name_cy: "") }

        it "shows the input" do
          expect(welsh_selection_option_translation_input.show_name_input?).to be true
        end
      end

      context "when the selection option has validation errors" do
        let(:new_input_data) { super().merge(name_cy: "a" * 251) }

        it "shows the input" do
          welsh_selection_option_translation_input.validate

          expect(welsh_selection_option_translation_input.show_name_input?).to be true
        end
      end
    end
  end
end
