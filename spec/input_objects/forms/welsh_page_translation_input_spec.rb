require "rails_helper"

RSpec.describe Forms::WelshPageTranslationInput, type: :model do
  subject(:welsh_page_translation_input) { described_class.new(new_input_data) }

  let(:page) { create_page }

  let(:condition) do
    create :condition, routing_page: page, answer_value: "Yes",
                       exit_page_heading: "You are ineligible",
                       exit_page_markdown: "Sorry, you are ineligible for this service."
  end

  let(:another_condition) { create :condition, routing_page: page, answer_value: "Yes", exit_page_heading: "Exit page heading", exit_page_markdown: "Exit page markdown" }

  let(:new_input_data) do
    {
      page:,
      question_text_cy: "Ydych chi'n adnewyddu trwydded?",
      hint_text_cy: "Dewiswch 'Ydw' os oes gennych drwydded ddilys eisoes.",
      page_heading_cy: "Trwyddedu",
      guidance_markdown_cy: "Mae'r rhan hon o'r ffurflen yn ymwneud â thrwyddedu.",
    }
  end

  def create_page(attributes = {})
    default_attributes = {
      id: 1,
      question_text: "Are you renewing a licence?",
      hint_text: "Choose 'Yes' if you already have a valid licence.",
      page_heading: "Licencing",
      guidance_markdown: "This part of the form concerns licencing.",
      question_text_cy: "",
      hint_text_cy: "",
      page_heading_cy: "",
      guidance_markdown_cy: "",
    }
    create(:page, default_attributes.merge(attributes))
  end

  describe "validations" do
    context "when the form is marked complete" do
      context "when the Welsh question text is missing" do
        let(:new_input_data) { super().merge(question_text_cy: nil) }

        it "is not valid" do
          expect(welsh_page_translation_input).not_to be_valid(:mark_complete)
          expect(welsh_page_translation_input.errors.full_messages_for(:question_text_cy)).to include "Question text cy #{I18n.t('activemodel.errors.models.forms/welsh_page_translation_input.attributes.question_text_cy.blank', question_number: page.position)}"
        end
      end

      context "when the Welsh question text is present" do
        context "when the Welsh question text is 251 characters or more" do
          let(:new_input_data) { super().merge(question_text_cy: "a" * 251) }

          it "is not valid" do
            expect(welsh_page_translation_input).not_to be_valid(:mark_complete)
            expect(welsh_page_translation_input.errors.full_messages_for(:question_text_cy)).to include "Question text cy #{I18n.t('activemodel.errors.models.forms/welsh_page_translation_input.attributes.question_text_cy.too_long', question_number: page.position, count: 250)}"
          end
        end

        context "when the Welsh question text is 250 characters or fewer" do
          let(:new_input_data) { super().merge(question_text_cy: "a" * 250) }

          it "is valid" do
            expect(welsh_page_translation_input).to be_valid(:mark_complete)
            expect(welsh_page_translation_input.errors.full_messages_for(:question_text_cy)).to be_empty
          end
        end
      end

      context "when the Welsh hint text is missing" do
        let(:new_input_data) { super().merge(hint_text_cy: nil) }

        context "when the form has hint text in English" do
          it "is not valid" do
            expect(welsh_page_translation_input).not_to be_valid(:mark_complete)
            expect(welsh_page_translation_input.errors.full_messages_for(:hint_text_cy)).to include "Hint text cy #{I18n.t('activemodel.errors.models.forms/welsh_page_translation_input.attributes.hint_text_cy.blank', question_number: page.position)}"
          end
        end

        context "when the form does not have hint text in English" do
          let(:page) { create_page(hint_text: nil) }

          it "is valid" do
            expect(welsh_page_translation_input).to be_valid(:mark_complete)
            expect(welsh_page_translation_input.errors.full_messages_for(:hint_text_cy)).to be_empty
          end
        end
      end

      context "when the Welsh hint text is present" do
        context "when the Welsh hint text is 501 characters or more" do
          let(:new_input_data) { super().merge(hint_text_cy: "a" * 501) }

          it "is not valid" do
            expect(welsh_page_translation_input).not_to be_valid(:mark_complete)
            expect(welsh_page_translation_input.errors.full_messages_for(:hint_text_cy)).to include "Hint text cy #{I18n.t('activemodel.errors.models.forms/welsh_page_translation_input.attributes.hint_text_cy.too_long', question_number: page.position, count: 500)}"
          end
        end

        context "when the Welsh hint text is 500 characters or fewer" do
          let(:new_input_data) { super().merge(hint_text_cy: "a" * 500) }

          it "is valid" do
            expect(welsh_page_translation_input).to be_valid(:mark_complete)
            expect(welsh_page_translation_input.errors.full_messages_for(:hint_text_cy)).to be_empty
          end
        end
      end

      context "when the Welsh page heading is missing" do
        let(:new_input_data) { super().merge(page_heading_cy: nil) }

        context "when the form has guidance markdown in English" do
          it "is not valid" do
            expect(welsh_page_translation_input).not_to be_valid(:mark_complete)
            expect(welsh_page_translation_input.errors.full_messages_for(:page_heading_cy)).to include "Page heading cy #{I18n.t('activemodel.errors.models.forms/welsh_page_translation_input.attributes.page_heading_cy.blank', question_number: page.position)}"
          end
        end

        context "when the form does not have guidance markdown in English" do
          let(:page) { create_page(page_heading: nil, guidance_markdown: nil) }

          it "is valid" do
            expect(welsh_page_translation_input).to be_valid(:mark_complete)
            expect(welsh_page_translation_input.errors.full_messages_for(:page_heading_cy)).to be_empty
          end
        end
      end

      context "when the Welsh page heading is present" do
        context "when the Welsh page heading is 251 characters or more" do
          let(:new_input_data) { super().merge(page_heading_cy: "a" * 251) }

          it "is not valid" do
            expect(welsh_page_translation_input).not_to be_valid(:mark_complete)
            expect(welsh_page_translation_input.errors.full_messages_for(:page_heading_cy)).to include "Page heading cy #{I18n.t('activemodel.errors.models.forms/welsh_page_translation_input.attributes.page_heading_cy.too_long', question_number: page.position, count: 250)}"
          end
        end

        context "when the Welsh page heading is 250 characters or fewer" do
          let(:new_input_data) { super().merge(page_heading_cy: "a" * 250) }

          it "is valid" do
            expect(welsh_page_translation_input).to be_valid(:mark_complete)
            expect(welsh_page_translation_input.errors.full_messages_for(:page_heading_cy)).to be_empty
          end
        end
      end

      context "when the Welsh guidance markdown is missing" do
        let(:new_input_data) { super().merge(guidance_markdown_cy: nil) }

        context "when the form has guidance markdown in English" do
          it "is not valid" do
            expect(welsh_page_translation_input).not_to be_valid(:mark_complete)
            expect(welsh_page_translation_input.errors.full_messages_for(:guidance_markdown_cy)).to include "Guidance markdown cy #{I18n.t('activemodel.errors.models.forms/welsh_page_translation_input.attributes.guidance_markdown_cy.blank', question_number: page.position)}"
          end
        end

        context "when the form does not have guidance markdown in English" do
          let(:page) { create_page(page_heading: nil, guidance_markdown: nil) }

          it "is valid" do
            expect(welsh_page_translation_input).to be_valid(:mark_complete)
            expect(welsh_page_translation_input.errors.full_messages_for(:guidance_markdown_cy)).to be_empty
          end
        end
      end

      context "when the Welsh guidance markdown is present" do
        it_behaves_like "a markdown field with headings allowed", :mark_complete do
          let(:model) { welsh_page_translation_input }
          let(:attribute) { :guidance_markdown_cy }
        end
      end

      context "when it's a none of the above question" do
        let(:page) do
          create_page(attributes_for(:page, :selection_with_none_of_the_above_question))
        end
        let(:new_input_data) do
          super().merge({
            none_of_the_above_question_cy: "Welsh none of the above question?",
            selection_options_cy_attributes: {
              "0" => { "id" => "0", "name_cy" => "First" },
              "1" => { "id" => "1", "name_cy" => "Second" },
            },
          })
        end

        context "when the none of the above question is present" do
          it "is valid" do
            expect(welsh_page_translation_input).to be_valid(:mark_complete)
            expect(welsh_page_translation_input.errors.full_messages_for(:none_of_the_above_question_cy)).to be_empty
          end
        end

        context "when the none of the above question is missing" do
          let(:new_input_data) { super().merge(none_of_the_above_question_cy: nil) }

          it "is invalid" do
            expect(welsh_page_translation_input).not_to be_valid(:mark_complete)
            expect(welsh_page_translation_input.errors.full_messages_for(:none_of_the_above_question_cy)).to include "None of the above question cy #{I18n.t('activemodel.errors.models.forms/welsh_page_translation_input.attributes.none_of_the_above_question_cy.blank', question_number: page.position)}"
          end
        end
      end
    end

    context "when the form is not marked complete" do
      context "when the Welsh question text is missing" do
        let(:new_input_data) { super().merge(question_text_cy: nil) }

        it "is valid" do
          expect(welsh_page_translation_input).to be_valid
          expect(welsh_page_translation_input.errors.full_messages_for(:question_text_cy)).to be_empty
        end
      end

      context "when the Welsh question text is present" do
        context "when the Welsh question text is 251 characters or more" do
          let(:new_input_data) { super().merge(question_text_cy: "a" * 251) }

          it "is not valid" do
            expect(welsh_page_translation_input).not_to be_valid
            expect(welsh_page_translation_input.errors.full_messages_for(:question_text_cy)).to include "Question text cy #{I18n.t('activemodel.errors.models.forms/welsh_page_translation_input.attributes.question_text_cy.too_long', question_number: page.position, count: 250)}"
          end
        end

        context "when the Welsh question text is 250 characters or fewer" do
          let(:new_input_data) { super().merge(question_text_cy: "a" * 250) }

          it "is valid" do
            expect(welsh_page_translation_input).to be_valid
            expect(welsh_page_translation_input.errors.full_messages_for(:question_text_cy)).to be_empty
          end
        end
      end

      context "when the Welsh hint text is missing" do
        let(:new_input_data) { super().merge(hint_text_cy: nil) }

        it "is valid" do
          expect(welsh_page_translation_input).to be_valid
          expect(welsh_page_translation_input.errors.full_messages_for(:hint_text_cy)).to be_empty
        end
      end

      context "when the Welsh hint text is present" do
        context "when the Welsh hint text is 501 characters or more" do
          let(:new_input_data) { super().merge(hint_text_cy: "a" * 501) }

          it "is not valid" do
            expect(welsh_page_translation_input).not_to be_valid
            expect(welsh_page_translation_input.errors.full_messages_for(:hint_text_cy)).to include "Hint text cy #{I18n.t('activemodel.errors.models.forms/welsh_page_translation_input.attributes.hint_text_cy.too_long', question_number: page.position, count: 500)}"
          end
        end

        context "when the Welsh hint text is 500 characters or fewer" do
          let(:new_input_data) { super().merge(hint_text_cy: "a" * 500) }

          it "is valid" do
            expect(welsh_page_translation_input).to be_valid
            expect(welsh_page_translation_input.errors.full_messages_for(:hint_text_cy)).to be_empty
          end
        end
      end

      context "when the Welsh page heading is missing" do
        let(:new_input_data) { super().merge(page_heading_cy: nil) }

        it "is valid" do
          expect(welsh_page_translation_input).to be_valid
          expect(welsh_page_translation_input.errors.full_messages_for(:page_heading_cy)).to be_empty
        end
      end

      context "when the Welsh page heading is present" do
        context "when the Welsh page heading is 251 characters or more" do
          let(:new_input_data) { super().merge(page_heading_cy: "a" * 251) }

          it "is not valid" do
            expect(welsh_page_translation_input).not_to be_valid
            expect(welsh_page_translation_input.errors.full_messages_for(:page_heading_cy)).to include "Page heading cy #{I18n.t('activemodel.errors.models.forms/welsh_page_translation_input.attributes.page_heading_cy.too_long', question_number: page.position, count: 250)}"
          end
        end

        context "when the Welsh page heading is 250 characters or fewer" do
          let(:new_input_data) { super().merge(page_heading_cy: "a" * 250) }

          it "is valid" do
            expect(welsh_page_translation_input).to be_valid
            expect(welsh_page_translation_input.errors.full_messages_for(:page_heading_cy)).to be_empty
          end
        end
      end

      context "when the Welsh guidance markdown is missing" do
        let(:new_input_data) { super().merge(guidance_markdown_cy: nil) }

        it "is valid" do
          expect(welsh_page_translation_input).to be_valid
          expect(welsh_page_translation_input.errors.full_messages_for(:guidance_markdown_cy)).to be_empty
        end
      end

      context "when the Welsh guidance markdown is present" do
        it_behaves_like "a markdown field with headings allowed", :mark_complete do
          let(:model) { welsh_page_translation_input }
          let(:attribute) { :guidance_markdown_cy }
        end
      end

      context "when the page has repeated selection options" do
        let(:page) do
          create_page(answer_type: "selection",
                      answer_settings: { only_one_option: "true", selection_options: [{ name: "Option 1", value: "Option 1" }, { name: "Option 2", value: "Option 2" }] })
        end
        let(:new_input_data) do
          super().merge({ selection_options_cy_attributes: {
            "0" => { "id" => "0", "name_cy" => "same" },
            "1" => { "id" => "1", "name_cy" => "same" },
          } })
        end

        it "is invalid" do
          expect(welsh_page_translation_input).not_to be_valid(:mark_complete)
          expect(welsh_page_translation_input.errors.full_messages_for(:selection_options_cy)).to include "Selection options cy #{I18n.t('activemodel.errors.models.forms/welsh_page_translation_input.attributes.selection_options_cy.uniqueness', question_number: page.position)}"
        end
      end

      context "when it's a none of the above question" do
        let(:page) do
          create_page(attributes_for(:page, :selection_with_none_of_the_above_question))
        end
        let(:new_input_data) do
          super().merge({
            none_of_the_above_question_cy: "Welsh none of the above question?",
            selection_options_cy_attributes: {
              "0" => { "id" => "0", "name_cy" => "First" },
              "1" => { "id" => "1", "name_cy" => "Second" },
            },
          })
        end

        context "when the none of the above question is missing" do
          let(:new_input_data) { super().merge(none_of_the_above_question_cy: nil) }

          it "is valid" do
            expect(welsh_page_translation_input).to be_valid
          end
        end

        context "when the none of the above question is shorter than 250 characters" do
          let(:new_input_data) { super().merge(none_of_the_above_question_cy: "a" * 249) }

          it "is valid" do
            expect(welsh_page_translation_input).to be_valid
          end
        end

        context "when the none of the above question is longer than 250 characters" do
          let(:new_input_data) { super().merge(none_of_the_above_question_cy: "a" * 251) }

          it "is invalid" do
            expect(welsh_page_translation_input).not_to be_valid
            expect(welsh_page_translation_input.errors.full_messages_for(:none_of_the_above_question_cy)).to include "None of the above question cy #{I18n.t('activemodel.errors.models.forms/welsh_page_translation_input.attributes.none_of_the_above_question_cy.too_long', count: 250, question_number: page.position)}"
          end
        end
      end
    end

    context "when any of the page's condition translations have errors" do
      let(:condition_translation) { Forms::WelshConditionTranslationInput.new(condition:) }
      let(:new_input_data) { super().merge(condition_translations: [condition_translation]) }

      it "is invalid" do
        expect(welsh_page_translation_input).not_to be_valid(:mark_complete)
        expect(welsh_page_translation_input.errors.full_messages_for(:exit_page_markdown_cy)).to include "Exit page markdown cy #{I18n.t('activemodel.errors.models.forms/welsh_condition_translation_input.attributes.exit_page_markdown_cy.blank', question_number: page.position)}"
      end
    end
  end

  describe "#submit" do
    it "returns true" do
      expect(welsh_page_translation_input.submit).to be true
    end

    it "updates the page's welsh attributes with the new values" do
      welsh_page_translation_input.submit
      page.reload

      expect(page.reload.question_text_cy).to eq(new_input_data[:question_text_cy])
      expect(page.reload.hint_text_cy).to eq(new_input_data[:hint_text_cy])
      expect(page.reload.page_heading_cy).to eq(new_input_data[:page_heading_cy])
      expect(page.reload.guidance_markdown_cy).to eq(new_input_data[:guidance_markdown_cy])
    end

    it "does not update any non-welsh attributes" do
      english_value_before = page.question_text
      welsh_page_translation_input.submit
      expect(page.question_text).to eq(english_value_before)
    end

    context "when the page has no hint text" do
      let(:page) { create_page(hint_text: nil) }

      it "clears the Welsh hint text" do
        welsh_page_translation_input.submit
        expect(page.reload.hint_text_cy).to be_nil
      end
    end

    context "when the page has no page heading or guidance markdown" do
      let(:page) { create_page(page_heading: nil, guidance_markdown: nil) }

      it "clears the Welsh page heading" do
        welsh_page_translation_input.submit
        expect(page.page_heading_cy).to be_nil
        expect(page.guidance_markdown_cy).to be_nil
      end
    end

    context "when the form includes condition translation objects" do
      let(:condition_translation) { Forms::WelshConditionTranslationInput.new(condition: condition, exit_page_heading_cy: "Nid ydych yn gymwys", exit_page_markdown_cy: "Mae'n ddrwg gennym, nid ydych yn gymwys ar gyfer y gwasanaeth hwn.") }
      let(:another_condition_translation) { Forms::WelshConditionTranslationInput.new(condition: another_condition, exit_page_heading_cy: "Welsh exit page heading", exit_page_markdown_cy: "Welsh exit page markdown") }

      let(:new_input_data) { super().merge(condition_translations: [condition_translation, another_condition_translation]) }

      it "submits the data on the condition translation objects" do
        welsh_page_translation_input.submit

        expect(condition.reload.exit_page_heading_cy).to eq("Nid ydych yn gymwys")
        expect(condition.reload.exit_page_markdown_cy).to eq("Mae'n ddrwg gennym, nid ydych yn gymwys ar gyfer y gwasanaeth hwn.")
        expect(another_condition.reload.exit_page_heading_cy).to eq("Welsh exit page heading")
        expect(another_condition.reload.exit_page_markdown_cy).to eq("Welsh exit page markdown")
      end
    end

    context "when the page has selection options" do
      let(:page) do
        create_page(answer_type: "selection",
                    answer_settings: { only_one_option: "true", selection_options: [{ name: "Option 1", value: "Option 1" }, { name: "Option 2", value: "Option 2" }] })
      end
      let(:new_input_data) do
        super().merge({ selection_options_cy_attributes: {
          "0" => { "id" => "0", "name_cy" => "welsh option 1" },
          "1" => { "id" => "1", "name_cy" => "welsh option 2" },
        } })
      end

      it "submits the data on the selection options" do
        welsh_page_translation_input.submit

        expect(page.reload.answer_settings_cy.selection_options.count).to eq(2)
        expect(page.reload.answer_settings_cy.selection_options.first.name).to eq("welsh option 1")
        expect(page.reload.answer_settings_cy.selection_options.first.value).to eq("Option 1")

        expect(page.reload.answer_settings_cy.selection_options.second.name).to eq("welsh option 2")
        expect(page.reload.answer_settings_cy.selection_options.second.value).to eq("Option 2")
      end

      context "when the submitted selection options are not in index order" do
        let(:new_input_data) do
          super().merge({ selection_options_cy_attributes: {
            "0" => { "id" => "1", "name_cy" => "welsh option 2" },
            "1" => { "id" => "0", "name_cy" => "welsh option 1" },
          } })
        end

        it "saves the selection options in the original English order" do
          welsh_page_translation_input.submit

          expect(page.reload.answer_settings_cy.selection_options.map(&:name)).to eq(["welsh option 1", "welsh option 2"])
          expect(page.reload.answer_settings_cy.selection_options.map(&:value)).to eq(["Option 1", "Option 2"])
        end
      end
    end

    context "when the page has a selection question with none of the above" do
      let(:page) do
        create_page(attributes_for(:page, :selection_with_none_of_the_above_question))
      end

      let(:new_input_data) do
        super().merge({ none_of_the_above_question_cy: "Welsh none of the above question?" })
      end

      it "assigns the welsh none of the above question text" do
        welsh_page_translation_input.submit

        expect(page.answer_settings_cy.none_of_the_above_question.question_text).to eq("Welsh none of the above question?")
      end
    end
  end

  describe "#assign_page_values" do
    it "loads the existing welsh attributes from the page" do
      welsh_page_translation_input = described_class.new(id: page.id)
      welsh_page_translation_input.assign_page_values

      expect(welsh_page_translation_input.question_text_cy).to eq(page.question_text_cy)
      expect(welsh_page_translation_input.hint_text_cy).to eq(page.hint_text_cy)
      expect(welsh_page_translation_input.page_heading_cy).to eq(page.page_heading_cy)
      expect(welsh_page_translation_input.guidance_markdown_cy).to eq(page.guidance_markdown_cy)
    end

    context "when the page has selection options" do
      let(:page) do
        create_page(answer_type: "selection",
                    answer_settings: { only_one_option: "true", selection_options: [{ name: "Option 1", value: "Option 1" }, { name: "Option 2", value: "Option 2" }] })
      end

      it "sets the welsh names to empty and keeps values" do
        welsh_page_translation_input.assign_page_values

        selection_options_cy = welsh_page_translation_input.selection_options_cy.map(&:as_selection_option)
        expect(selection_options_cy.count).to eq(2)
        expect(selection_options_cy).to eq([
          { name: "", value: "Option 1" },
          { name: "", value: "Option 2" },
        ])
      end
    end

    context "when the page has selection options and existing Welsh options" do
      let(:page) do
        create_page(answer_type: "selection",
                    answer_settings: { only_one_option: "true", selection_options: [{ name: "New value 1", value: "New value 1" }, { name: "New value 2", value: "New value 2" }] },
                    answer_settings_cy: { only_one_option: "true", selection_options: [{ name: "Welsh option 1", value: "Old value 1" }, { name: "Welsh option 2", value: "Old value 2" }] })
      end

      it "keeps the welsh text but updates the new values" do
        welsh_page_translation_input.assign_page_values

        selection_options_cy = welsh_page_translation_input.selection_options_cy.map(&:as_selection_option)
        expect(selection_options_cy.count).to eq(2)
        expect(selection_options_cy).to eq([
          { name: "Welsh option 1", value: "New value 1" },
          { name: "Welsh option 2", value: "New value 2" },
        ])
      end
    end

    context "when the page has selection options and partial Welsh options" do
      let(:page) do
        create_page(answer_type: "selection",
                    answer_settings: { only_one_option: "true", selection_options: [{ name: "Yes", value: "Yes" }, { name: "No", value: "No" }, { name: "Maybe", value: "Maybe" }] },
                    answer_settings_cy: { only_one_option: "true", selection_options: [{ name: "Welsh option 1", value: "Yes" }, { name: "", value: "Option 2" }] })
      end

      it "keeps the welsh text and adds blanks for missing values" do
        welsh_page_translation_input.assign_page_values

        selection_options_cy = welsh_page_translation_input.selection_options_cy.map(&:as_selection_option)

        expect(selection_options_cy).to eq([
          { name: "Welsh option 1", value: "Yes" },
          { name:  "", value: "No" },
          { name:  "", value: "Maybe" },
        ])
      end
    end

    context "when the page has a selection question with none of the above" do
      let(:page) do
        create_page(attributes_for(:page, :selection_with_none_of_the_above_question))
      end

      it "none_of_the_above_question_cy is nil" do
        welsh_page_translation_input.assign_page_values
        expect(welsh_page_translation_input.none_of_the_above_question_cy).to be_nil
      end

      context "when the welsh none of the above question is present" do
        let(:page) do
          create_page(attributes_for(:page,
                                     :selection_with_none_of_the_above_question,
                                     answer_settings_cy: {
                                       selection_options: [
                                         { name: "Welsh option 1", value: "Option 1" },
                                         { name: "Welsh option 2", value: "Option 2" },
                                       ],
                                       none_of_the_above_question: {
                                         question_text: "Welsh none of the above question?",
                                         is_optional: "true",
                                       },
                                     }))
        end

        it "none_of_the_above_question_cy is the welsh text" do
          welsh_page_translation_input.assign_page_values
          expect(welsh_page_translation_input.none_of_the_above_question_cy).to eq("Welsh none of the above question?")
        end
      end
    end
  end

  describe "#page_has_hint_text?" do
    context "when the page has hint_text" do
      let(:page) { create_page(hint_text: "Choose 'Yes' if you already have a valid licence.") }

      it "returns true" do
        expect(welsh_page_translation_input.page_has_hint_text?).to be true
      end
    end

    context "when the page has no hint_text" do
      let(:page) { create_page(hint_text: nil) }

      it "returns false" do
        expect(welsh_page_translation_input.page_has_hint_text?).to be false
      end
    end
  end

  describe "#page_has_page_heading_and_guidance_markdown?" do
    context "when the page has a page_heading" do
      let(:page) { create_page(page_heading: "Licencing") }

      it "returns true" do
        expect(welsh_page_translation_input.page_has_page_heading_and_guidance_markdown?).to be true
      end
    end

    context "when the page has no page_heading and guidance_markdown" do
      let(:page) { create_page(page_heading: nil, guidance_markdown: nil) }

      it "returns false" do
        expect(welsh_page_translation_input.page_has_page_heading_and_guidance_markdown?).to be false
      end
    end
  end

  describe "#page_has_none_of_the_above_question?" do
    it "is false" do
      expect(welsh_page_translation_input.page_has_none_of_the_above_question?).to be false
    end

    context "when the page has a selection question with none of the above" do
      let(:page) do
        create_page(attributes_for(:page, :selection_with_none_of_the_above_question))
      end

      it "is true" do
        expect(welsh_page_translation_input.page_has_none_of_the_above_question?).to be true
      end
    end
  end

  describe "#all_fields_empty?" do
    context "when the welsh page fields are not empty" do
      it "returns false" do
        expect(welsh_page_translation_input.all_fields_empty?).to be false
      end
    end

    context "when the welsh page fields are all empty" do
      let(:new_input_data) { { page:, question_text_cy: "", hint_text_cy: "", page_heading_cy: "", guidance_markdown_cy: "" } }

      it "returns true" do
        expect(welsh_page_translation_input.all_fields_empty?).to be true
      end
    end
  end

  describe "#blanked?" do
    let(:page) do
      create_page(answer_type: "selection",
                  answer_settings: { only_one_option: "true", selection_options: [{ name: "Option 1", value: "Option 1" }, { name: "Option 2", value: "Option 2" }] })
    end
    let(:new_input_data) do
      super().merge(
        question_text_cy: "",
        hint_text_cy: "",
        page_heading_cy: "",
        guidance_markdown_cy: "",
        condition_translations: [condition_translation],
        selection_options_cy_attributes: {
          "0" => { "id" => "0", "name_cy" => "" },
          "1" => { "id" => "1", "name_cy" => "" },
        },
      )
    end
    let(:condition_translation) { Forms::WelshConditionTranslationInput.new(condition: condition, exit_page_heading_cy: "", exit_page_markdown_cy: "") }
    let(:selection_options_cy) { welsh_page_translation_input.selection_options_cy.map(&:as_selection_option) }

    it "returns true when all fields are blank" do
      expect(welsh_page_translation_input.blanked?).to be true
    end

    context "when the welsh page fields are not all blank" do
      let(:new_input_data) { super().merge(question_text_cy: "New question text") }

      it "returns false" do
        expect(welsh_page_translation_input.blanked?).to be false
      end
    end

    context "when the condition is not blank" do
      let(:condition_translation) { Forms::WelshConditionTranslationInput.new(condition: condition, exit_page_heading_cy: "Heading", exit_page_markdown_cy: "markdown") }

      it "returns false" do
        expect(welsh_page_translation_input.blanked?).to be false
      end
    end

    context "when the selection optiosn are not all blank" do
      let(:new_input_data) do
        super().merge(
          question_text_cy: "New question text",
          condition_translations: [],
          selection_options_cy_attributes: {
            "0" => { "id" => "0", "name_cy" => "welsh option 1" },
            "1" => { "id" => "1", "name_cy" => "" },
          },
        )
      end

      it "returns false" do
        expect(welsh_page_translation_input.blanked?).to be false
      end
    end
  end
end
