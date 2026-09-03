require "rails_helper"

RSpec.describe Forms::WelshExitPageTranslationInput, type: :model do
  subject(:welsh_exit_page_translation_input) { described_class.new(new_input_data) }

  let(:exit_page) { create_exit_page }
  let(:page) { create :page }

  let(:new_input_data) do
    {
      exit_page:,
      position: 1,
      markdown_cy: "Nid ydych yn gymwys",
      heading_cy: "Mae'n ddrwg gennym, nid ydych yn gymwys ar gyfer y gwasanaeth hwn.",
    }
  end

  def create_exit_page(attributes = {})
    default_attributes = {
      id: 1,
      question_page: page,
      markdown: "You are ineligible",
      heading: "Sorry, you are ineligible for this service.",
      markdown_cy: "",
      heading_cy: "",
    }
    create(:exit_page, default_attributes.merge(attributes))
  end

  describe "validations" do
    context "when the form is marked complete" do
      let(:validation_context) { :mark_complete }

      context "when the Welsh exit page heading is missing" do
        let(:new_input_data) { super().merge(heading_cy: nil) }

        it "is not valid" do
          expect(welsh_exit_page_translation_input).not_to be_valid(validation_context)
          expect(welsh_exit_page_translation_input.errors.full_messages_for(:heading_cy)).to include "Heading cy #{I18n.t('activemodel.errors.models.forms/welsh_condition_translation_input.attributes.exit_page_heading_cy.blank', question_number: exit_page.question_page.position)}"
        end
      end

      context "when the Welsh exit page heading is present" do
        context "when the Welsh exit page heading is 251 characters or more" do
          let(:new_input_data) { super().merge(heading_cy: "a" * 251) }

          it "is not valid" do
            expect(welsh_exit_page_translation_input).not_to be_valid(validation_context)
            expect(welsh_exit_page_translation_input.errors.full_messages_for(:heading_cy)).to include "Heading cy #{I18n.t('activemodel.errors.models.forms/welsh_condition_translation_input.attributes.exit_page_heading_cy.too_long', question_number: exit_page.question_page.position, count: 250)}"
          end
        end

        context "when the Welsh exit page heading is 250 characters or fewer" do
          let(:new_input_data) { super().merge(heading_cy: "a" * 250) }

          it "is valid" do
            expect(welsh_exit_page_translation_input).to be_valid(validation_context)
            expect(welsh_exit_page_translation_input.errors.full_messages_for(:heading_cy)).to be_empty
          end
        end
      end

      context "when the Welsh exit page markdown is missing" do
        let(:new_input_data) { super().merge(markdown_cy: nil) }

        it "is not valid" do
          expect(welsh_exit_page_translation_input).not_to be_valid(validation_context)
          expect(welsh_exit_page_translation_input.errors.full_messages_for(:markdown_cy)).to include "Markdown cy #{I18n.t('activemodel.errors.models.forms/welsh_condition_translation_input.attributes.exit_page_markdown_cy.blank', question_number: exit_page.question_page.position)}"
        end
      end

      context "when the Welsh exit page markdown is present" do
        it_behaves_like "a markdown field with headings allowed", :mark_complete do
          let(:model) { welsh_exit_page_translation_input }
          let(:attribute) { :markdown_cy }
        end
      end
    end

    context "when the form is not marked complete" do
      let(:validation_context) { nil }

      context "when the Welsh exit page heading is missing" do
        let(:new_input_data) { super().merge(heading_cy: nil) }

        it "is valid" do
          expect(welsh_exit_page_translation_input).to be_valid(validation_context)
          expect(welsh_exit_page_translation_input.errors.full_messages_for(:heading_cy)).to be_empty
        end
      end

      context "when the Welsh exit page heading is present" do
        context "when the Welsh exit page heading is 251 characters or more" do
          let(:new_input_data) { super().merge(heading_cy: "a" * 251) }

          it "is not valid" do
            expect(welsh_exit_page_translation_input).not_to be_valid(validation_context)
            expect(welsh_exit_page_translation_input.errors.full_messages_for(:heading_cy)).to include "Heading cy #{I18n.t('activemodel.errors.models.forms/welsh_condition_translation_input.attributes.exit_page_heading_cy.too_long', question_number: exit_page.question_page.position, count: 250)}"
          end
        end

        context "when the Welsh exit page heading is 250 characters or fewer" do
          let(:new_input_data) { super().merge(heading_cy: "a" * 250) }

          it "is valid" do
            expect(welsh_exit_page_translation_input).to be_valid(validation_context)
            expect(welsh_exit_page_translation_input.errors.full_messages_for(:heading_cy)).to be_empty
          end
        end
      end

      context "when the Welsh exit page markdown is missing" do
        let(:new_input_data) { super().merge(markdown_cy: nil) }

        it "is valid" do
          expect(welsh_exit_page_translation_input).to be_valid(validation_context)
          expect(welsh_exit_page_translation_input.errors.full_messages_for(:markdown_cy)).to be_empty
        end
      end

      context "when the Welsh exit page markdown is present" do
        it_behaves_like "a markdown field with headings allowed", :mark_complete do
          let(:model) { welsh_exit_page_translation_input }
          let(:attribute) { :markdown_cy }
        end
      end
    end
  end

  describe "#submit" do
    it "returns true" do
      expect(welsh_exit_page_translation_input.submit).to be true
    end

    it "updates the exit page's welsh attributes with the new values" do
      welsh_exit_page_translation_input.submit
      exit_page.reload

      expect(exit_page.reload.markdown_cy).to eq(new_input_data[:markdown_cy])
      expect(exit_page.reload.heading_cy).to eq(new_input_data[:heading_cy])
    end

    it "does not update any non-welsh attributes" do
      english_value_before = exit_page.markdown
      welsh_exit_page_translation_input.submit
      expect(exit_page.reload.markdown).to eq(english_value_before)
    end
  end

  describe "#assign_page_values" do
    it "loads the existing welsh attributes from the page" do
      welsh_exit_page_translation_input = described_class.new(exit_page:)
      welsh_exit_page_translation_input.assign_exit_page_values

      expect(welsh_exit_page_translation_input.markdown_cy).to eq(exit_page.markdown_cy)
      expect(welsh_exit_page_translation_input.heading_cy).to eq(exit_page.heading_cy)
    end
  end

  describe "#form_field_id" do
    let(:exit_page) do
      create_exit_page(id: 999)
    end

    it "returns the custom ID for each attribute" do
      expect(welsh_exit_page_translation_input.form_field_id(:markdown_cy)).to eq "forms_welsh_exit_page_translation_input_#{exit_page.id}_exit_page_translations_markdown_cy"
      expect(welsh_exit_page_translation_input.form_field_id(:heading_cy)).to eq "forms_welsh_exit_page_translation_input_#{exit_page.id}_exit_page_translations_heading_cy"
    end
  end

  describe "#all_fields_empty?" do
    context "when the welsh exit page fields are not empty" do
      it "returns false" do
        expect(welsh_exit_page_translation_input.all_fields_empty?).to be false
      end
    end

    context "when the welsh condition fields are all empty" do
      let(:new_input_data) { { exit_page:, markdown_cy: "", heading_cy: "" } }

      it "returns true" do
        expect(welsh_exit_page_translation_input.all_fields_empty?).to be true
      end
    end
  end
end
