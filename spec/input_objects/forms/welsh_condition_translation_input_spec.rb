require "rails_helper"

RSpec.describe Forms::WelshConditionTranslationInput, type: :model do
  subject(:welsh_condition_translation_input) { described_class.new(new_input_data) }

  let(:condition) { create_condition }
  let(:page) { create :page, position: 1 }

  let(:new_input_data) do
    {
      condition:,
      exit_page_markdown_cy: "Nid ydych yn gymwys",
      exit_page_heading_cy: "Mae'n ddrwg gennym, nid ydych yn gymwys ar gyfer y gwasanaeth hwn.",
    }
  end

  def create_condition(attributes = {})
    default_attributes = {
      answer_value: "Yes",
      exit_page_markdown: "You are ineligible",
      exit_page_heading: "Sorry, you are ineligible for this service.",
      exit_page_markdown_cy: "",
      exit_page_heading_cy: "",
      routing_page: page,
    }
    create(:condition, default_attributes.merge(attributes))
  end

  describe "validations" do
    context "when the form is marked complete" do
      let(:validation_context) { :mark_complete }

      context "when the Welsh exit page heading is missing" do
        let(:new_input_data) { super().merge(exit_page_heading_cy: nil) }

        context "when the form has an exit page in English" do
          it "is not valid" do
            expect(welsh_condition_translation_input).not_to be_valid(validation_context)
            expect(welsh_condition_translation_input.errors.full_messages_for(:exit_page_heading_cy)).to include "Exit page heading cy #{I18n.t('activemodel.errors.models.forms/welsh_condition_translation_input.attributes.exit_page_heading_cy.blank', question_number: condition.routing_page.position)}"
          end
        end

        context "when the form does not have an exit page in English" do
          let(:condition) { create_condition(exit_page_heading: nil, exit_page_markdown: nil) }

          it "is valid" do
            expect(welsh_condition_translation_input).to be_valid(validation_context)
            expect(welsh_condition_translation_input.errors.full_messages_for(:exit_page_heading_cy)).to be_empty
          end
        end
      end

      context "when the Welsh exit page heading is present" do
        context "when the Welsh exit page heading is 251 characters or more" do
          let(:new_input_data) { super().merge(exit_page_heading_cy: "a" * 251) }

          it "is not valid" do
            expect(welsh_condition_translation_input).not_to be_valid(validation_context)
            expect(welsh_condition_translation_input.errors.full_messages_for(:exit_page_heading_cy)).to include "Exit page heading cy #{I18n.t('activemodel.errors.models.forms/welsh_condition_translation_input.attributes.exit_page_heading_cy.too_long', question_number: condition.routing_page.position, count: 250)}"
          end
        end

        context "when the Welsh exit page heading is 250 characters or fewer" do
          let(:new_input_data) { super().merge(exit_page_heading_cy: "a" * 250) }

          it "is valid" do
            expect(welsh_condition_translation_input).to be_valid(validation_context)
            expect(welsh_condition_translation_input.errors.full_messages_for(:exit_page_heading_cy)).to be_empty
          end
        end
      end

      context "when the Welsh exit page markdown is missing" do
        let(:new_input_data) { super().merge(exit_page_markdown_cy: nil) }

        context "when the form has an exit page in English" do
          it "is not valid" do
            expect(welsh_condition_translation_input).not_to be_valid(validation_context)
            expect(welsh_condition_translation_input.errors.full_messages_for(:exit_page_markdown_cy)).to include "Exit page markdown cy #{I18n.t('activemodel.errors.models.forms/welsh_condition_translation_input.attributes.exit_page_markdown_cy.blank', question_number: condition.routing_page.position)}"
          end
        end

        context "when the form does not have an exit page in English" do
          let(:condition) { create_condition(exit_page_heading: nil, exit_page_markdown: nil) }

          it "is valid" do
            expect(welsh_condition_translation_input).to be_valid(validation_context)
            expect(welsh_condition_translation_input.errors.full_messages_for(:exit_page_markdown_cy)).to be_empty
          end
        end
      end

      context "when the Welsh exit page markdown is present" do
        it_behaves_like "a markdown field with headings allowed", :mark_complete do
          let(:model) { welsh_condition_translation_input }
          let(:attribute) { :exit_page_markdown_cy }
        end
      end
    end

    context "when the form is not marked complete" do
      let(:validation_context) { nil }

      context "when the Welsh exit page heading is missing" do
        let(:new_input_data) { super().merge(exit_page_heading_cy: nil) }

        it "is valid" do
          expect(welsh_condition_translation_input).to be_valid(validation_context)
          expect(welsh_condition_translation_input.errors.full_messages_for(:exit_page_heading_cy)).to be_empty
        end
      end

      context "when the Welsh exit page heading is present" do
        context "when the Welsh exit page heading is 251 characters or more" do
          let(:new_input_data) { super().merge(exit_page_heading_cy: "a" * 251) }

          it "is not valid" do
            expect(welsh_condition_translation_input).not_to be_valid(validation_context)
            expect(welsh_condition_translation_input.errors.full_messages_for(:exit_page_heading_cy)).to include "Exit page heading cy #{I18n.t('activemodel.errors.models.forms/welsh_condition_translation_input.attributes.exit_page_heading_cy.too_long', question_number: condition.routing_page.position, count: 250)}"
          end
        end

        context "when the Welsh exit page heading is 250 characters or fewer" do
          let(:new_input_data) { super().merge(exit_page_heading_cy: "a" * 250) }

          it "is valid" do
            expect(welsh_condition_translation_input).to be_valid(validation_context)
            expect(welsh_condition_translation_input.errors.full_messages_for(:exit_page_heading_cy)).to be_empty
          end
        end
      end

      context "when the Welsh exit page markdown is missing" do
        let(:new_input_data) { super().merge(exit_page_markdown_cy: nil) }

        it "is valid" do
          expect(welsh_condition_translation_input).to be_valid(validation_context)
          expect(welsh_condition_translation_input.errors.full_messages_for(:exit_page_markdown_cy)).to be_empty
        end
      end

      context "when the Welsh exit page markdown is present" do
        it_behaves_like "a markdown field with headings allowed", :mark_complete do
          let(:model) { welsh_condition_translation_input }
          let(:attribute) { :exit_page_markdown_cy }
        end
      end
    end
  end

  describe "#submit" do
    it "returns true" do
      expect(welsh_condition_translation_input.submit).to be true
    end

    it "updates the condition's welsh attributes with the new values" do
      welsh_condition_translation_input.submit
      condition.reload

      expect(condition.reload.exit_page_markdown_cy).to eq(new_input_data[:exit_page_markdown_cy])
      expect(condition.reload.exit_page_heading_cy).to eq(new_input_data[:exit_page_heading_cy])
    end

    it "does not update any non-welsh attributes" do
      english_value_before = condition.exit_page_markdown
      welsh_condition_translation_input.submit
      expect(condition.reload.exit_page_markdown).to eq(english_value_before)
    end

    context "when the condition has no exit page markdown" do
      let(:condition) { create_condition(exit_page_markdown: nil) }

      it "clears the Welsh exit page markdown and heading" do
        welsh_condition_translation_input.submit
        expect(condition.reload.exit_page_markdown_cy).to be_nil
        expect(condition.reload.exit_page_heading_cy).to be_nil
      end
    end
  end

  describe "#assign_condition_values" do
    it "loads the existing welsh attributes from the page" do
      welsh_condition_translation_input = described_class.new(condition:)
      welsh_condition_translation_input.assign_condition_values

      expect(welsh_condition_translation_input.exit_page_markdown_cy).to eq(condition.exit_page_markdown_cy)
      expect(welsh_condition_translation_input.exit_page_heading_cy).to eq(condition.exit_page_heading_cy)
    end
  end

  describe "#assign_from_spreadsheet" do
    subject(:welsh_condition_translation_input) { described_class.new(condition:) }

    context "when the spreadsheet data contains Welsh translations for all fields" do
      let(:spreadsheet_data) do
        {
          "Question 1 - exit page heading" => "Welsh heading from spreadsheet",
          "Question 1 - exit page content" => "Welsh markdown from spreadsheet",
          "Question 2 - exit page heading" => "Another condition translation (ignored)",
          "Question 1 - question text" => "Page field translation (ignored)",
        }
      end

      it "assigns the welsh attributes from the spreadsheet data" do
        welsh_condition_translation_input.assign_from_spreadsheet(spreadsheet_data)

        expect(welsh_condition_translation_input.exit_page_heading_cy).to eq("Welsh heading from spreadsheet")
        expect(welsh_condition_translation_input.exit_page_markdown_cy).to eq("Welsh markdown from spreadsheet")
      end
    end

    context "when the spreadsheet data does not include keys for all fields" do
      let(:condition) { create_condition(exit_page_markdown_cy: "Welsh markdown on form") }
      let(:spreadsheet_data) do
        {
          "Question 1 - exit page heading" => "Welsh heading from spreadsheet",
        }
      end

      it "uses the Welsh already set on the condition for fields not present in the spreadsheet data" do
        welsh_condition_translation_input.assign_from_spreadsheet(spreadsheet_data)

        expect(welsh_condition_translation_input.exit_page_heading_cy).to eq("Welsh heading from spreadsheet")
        expect(welsh_condition_translation_input.exit_page_markdown_cy).to eq("Welsh markdown on form")
      end
    end

    context "when the spreadsheet data includes blank values" do
      let(:condition) { create_condition(exit_page_markdown_cy: "Welsh markdown on form", exit_page_heading_cy: "Welsh heading on form") }
      let(:spreadsheet_data) do
        {
          "Question 1 - exit page heading" => "Welsh heading from spreadsheet",
          "Question 1 - exit page content" => "",
        }
      end

      it "uses the Welsh already set on the condition for fields with blank values in the spreadsheet data" do
        welsh_condition_translation_input.assign_from_spreadsheet(spreadsheet_data)

        expect(welsh_condition_translation_input.exit_page_heading_cy).to eq("Welsh heading from spreadsheet")
        expect(welsh_condition_translation_input.exit_page_markdown_cy).to eq("Welsh markdown on form")
      end
    end
  end

  describe "#condition_has_exit_page?" do
    context "when the condition has an exit page" do
      let(:condition) do
        create_condition(exit_page_heading: "You are ineligible",
                         exit_page_markdown: "Sorry, you are ineligible for this service.")
      end

      it "returns true" do
        expect(welsh_condition_translation_input.condition_has_exit_page?).to be true
      end
    end

    context "when the condition has no exit page" do
      let(:condition) do
        create_condition(exit_page_heading: nil,
                         exit_page_markdown: nil)
      end

      it "returns false" do
        expect(welsh_condition_translation_input.condition_has_exit_page?).to be false
      end
    end
  end

  describe "#form_field_id" do
    let(:condition) do
      create_condition(id: 999)
    end

    it "returns the custom ID for each attribute" do
      expect(welsh_condition_translation_input.form_field_id(:exit_page_markdown_cy)).to eq "forms_welsh_condition_translation_input_#{condition.id}_condition_translations_exit_page_markdown_cy"
      expect(welsh_condition_translation_input.form_field_id(:exit_page_heading_cy)).to eq "forms_welsh_condition_translation_input_#{condition.id}_condition_translations_exit_page_heading_cy"
    end
  end

  describe "#all_fields_empty?" do
    context "when the welsh condition fields are not empty" do
      it "returns false" do
        expect(welsh_condition_translation_input.all_fields_empty?).to be false
      end
    end

    context "when the welsh condition fields are all empty" do
      let(:new_input_data) { { condition:, exit_page_markdown_cy: "", exit_page_heading_cy: "" } }

      it "returns true" do
        expect(welsh_condition_translation_input.all_fields_empty?).to be true
      end
    end
  end
end
