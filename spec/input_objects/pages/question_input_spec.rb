require "rails_helper"

RSpec.describe Pages::QuestionInput, type: :model do
  let(:form) { create :form }
  let(:answer_settings) { { foo: "bar" } }
  let(:question_input) do
    build(:question_input, answer_type:, question_text:, draft_question:, is_optional:,
                           is_repeatable:, form_id: form.id, answer_settings:, page_heading: draft_question.page_heading,
                           guidance_markdown: draft_question.guidance_markdown)
  end
  let(:draft_question) { build :address_draft_question, :with_guidance, question_text:, form_id: form.id }
  let(:question_text) { "What is your full name?" }
  let(:is_optional) { "false" }
  let(:is_repeatable) { "false" }
  let(:answer_type) { draft_question.answer_type }

  it "has a valid factory" do
    expect(build(:question_input)).to be_valid
  end

  describe "validations" do
    describe "#question_text" do
      it "is invalid given nil question text" do
        error_message = I18n.t("activemodel.errors.models.pages/question_input.attributes.question_text.blank")
        question_input.question_text = nil
        expect(question_input).to be_invalid
        expect(question_input.errors[:question_text]).to include(error_message)
      end

      it "is invalid given empty string question text" do
        error_message = I18n.t("activemodel.errors.models.pages/question_input.attributes.question_text.blank")
        question_input.question_text = ""
        expect(question_input).to be_invalid
        expect(question_input.errors[:question_text]).to include(error_message)
      end

      it "is valid if question text below 250 characters" do
        expect(question_input).to be_valid
      end

      context "when question text is 250 characters" do
        let(:question_text) { "A" * 250 }

        it "is valid" do
          expect(question_input).to be_valid
        end
      end

      context "when question text more than 250 characters" do
        let(:question_text) { "A" * 251 }

        it "is invalid" do
          expect(question_input).to be_invalid
        end

        it "has an error message" do
          question_input.valid?
          expect(question_input.errors[:question_text]).to include("Question text must be 250 characters or less")
        end
      end

      context "when the answer type is file" do
        let(:answer_type) { "file" }

        context "when question text is blank" do
          let(:question_text) { "" }

          it "has a file answer type specific error message" do
            expect(question_input).to be_invalid
            error_message = I18n.t("activemodel.errors.models.pages/question_input.attributes.question_text.blank_file")
            expect(question_input.errors[:question_text]).to include(error_message)
          end
        end

        context "when question text more than 250 characters" do
          let(:question_text) { "A" * 251 }

          it "has a file answer type specific error message" do
            expect(question_input).to be_invalid
            expect(question_input.errors[:question_text]).to include("Your text to ask for a file must be 250 characters or less")
          end
        end
      end
    end

    describe "#hint_text" do
      let(:question_input) { build :question_input, hint_text:, draft_question: }
      let(:hint_text) { "Enter your full name as it appears in your passport" }

      it "is valid if hint text is empty" do
        question_input.hint_text = nil
        expect(question_input).to be_valid
      end

      it "is valid if hint text below 500 characters" do
        expect(question_input).to be_valid
      end

      context "when hint text 500 characters" do
        let(:hint_text) { "A" * 500 }

        it "is valid" do
          expect(question_input).to be_valid
        end
      end

      context "when hint text more than 500 characters" do
        let(:hint_text) { "A" * 501 }

        it "is invalid" do
          expect(question_input).not_to be_valid
        end

        it "has an error message" do
          question_input.valid?
          expect(question_input.errors[:hint_text]).to include(I18n.t("activemodel.errors.models.pages/question_input.attributes.hint_text.too_long", count: 500))
        end
      end
    end

    describe "#is_optional" do
      let(:question_input) { build :question_input, is_optional:, draft_question: }

      context "when is_optional is nil" do
        let(:is_optional) { nil }

        it "is invalid" do
          expect(question_input).not_to be_valid
        end

        it "has an error message" do
          question_input.valid?
          expect(question_input.errors[:is_optional]).to include(I18n.t("activemodel.errors.models.pages/question_input.attributes.is_optional.inclusion"))
        end
      end

      context "when is_optional is true" do
        let(:is_optional) { "true" }

        it "is valid" do
          expect(question_input).to be_valid
        end

        it "has no error message" do
          question_input.valid?
          expect(question_input.errors[:is_optional]).to be_empty
        end
      end

      context "when is_optional is false" do
        let(:is_optional) { "false" }

        it "is valid" do
          expect(question_input).to be_valid
        end

        it "has no error message" do
          question_input.valid?
          expect(question_input.errors[:is_optional]).to be_empty
        end
      end
    end

    describe "#is_repeatable" do
      let(:question_input) { build :question_input, is_repeatable:, draft_question: }

      context "and is_repeatable is nil" do
        let(:is_repeatable) { nil }

        it "is invalid" do
          expect(question_input).not_to be_valid
        end

        it "has an error message" do
          question_input.valid?
          expect(question_input.errors[:is_repeatable]).to include(I18n.t("activemodel.errors.models.pages/question_input.attributes.is_repeatable.inclusion"))
        end
      end

      context "and is_repeatable is true" do
        let(:is_repeatable) { "true" }

        it "is valid" do
          expect(question_input).to be_valid
        end

        it "has no error message" do
          question_input.valid?
          expect(question_input.errors[:is_repeatable]).to be_empty
        end
      end

      context "and is_repeatable is false" do
        let(:is_repeatable) { "false" }

        it "is valid" do
          expect(question_input).to be_valid
        end

        it "has no error message" do
          question_input.valid?
          expect(question_input.errors[:is_repeatable]).to be_empty
        end
      end
    end

    context "when not given a draft_question" do
      let(:question_input) do
        build(:question_input, answer_type:, question_text:, draft_question: nil, is_optional:,
                               is_repeatable:, form_id: form.id)
      end

      it "is invalid" do
        expect(question_input).to be_invalid
      end
    end

    describe "selection options" do
      let(:selection_options) { (1..31).to_a.map { |i| { name: i.to_s } } }
      let(:only_one_option) { "false" }
      let(:draft_question) { build :selection_draft_question, answer_settings: { selection_options:, only_one_option: }, form_id: form.id }

      context "when only_one_option is true" do
        let(:only_one_option) { "true" }

        context "when there are more than 30 options" do
          it "is valid" do
            expect(question_input).to be_valid
          end
        end
      end

      context "when only_one_option is false" do
        context "when there are 30 options" do
          let(:selection_options) { (1..30).to_a.map { |i| { name: i.to_s } } }

          it "is valid" do
            expect(question_input).to be_valid
          end
        end

        context "when there are more than 30 options" do
          it "is invalid" do
            expect(question_input).to be_invalid
            expect(question_input.errors[:selection_options])
              .to include(I18n.t("activemodel.errors.models.pages/question_input.attributes.selection_options.too_many_selection_options"))
          end
        end
      end

      context "when answer type is not selection" do
        let(:draft_question) { build :name_draft_question, answer_settings: { selection_options:, only_one_option: }, form_id: form.id }

        it "is valid" do
          expect(question_input).to be_valid
        end
      end
    end
  end

  describe "#submit" do
    it "returns false if the form is invalid" do
      allow(question_input).to receive(:invalid?).and_return(true)
      expect(question_input.submit).to be false
    end

    context "when form is valid valid" do
      before do
        question_input.question_text = "How old are you?"
        question_input.hint_text = "As a number"
        question_input.is_optional = "false"
        question_input.is_repeatable = "true"
        question_input.submit
      end

      it "sets a draft_question question_text" do
        expect(question_input.draft_question.question_text).to eq question_input.question_text
      end

      it "sets a draft_question hint_text" do
        expect(question_input.draft_question.hint_text).to eq question_input.hint_text
      end

      it "sets a draft_question is_optional" do
        expect(question_input.draft_question.is_optional.to_s).to eq question_input.is_optional
      end

      it "sets a draft_question is_repeatable" do
        expect(question_input.draft_question.is_repeatable.to_s).to eq question_input.is_repeatable
      end
    end
  end

  context "when the form has a Welsh translation" do
    let(:form) { create :form, available_languages: %w[en cy] }

    context "when the page has selection options" do
      let(:draft_question) { build :selection_draft_question, form_id: form.id }
      let(:answer_settings) { { selection_options: [{ name: "Option 1", value: "Option 1" }, { name: "Option 2", value: "Option 2" }] } }

      it "sets the welsh answer_settings to blank selection options" do
        question_input.question_text = "Choose an option"
        question_input.is_optional = "false"
        question_input.is_repeatable = "false"
        page = question_input.submit
        expect(page.answer_settings_cy.as_json).to eq({ "selection_options" => [{ "name" => "", "value" => "Option 1" }, { "name" => "", "value" => "Option 2" }] })
      end
    end

    context "when the question is a selection question with none of the above" do
      let(:draft_question) { build :selection_draft_question, :with_optional_none_of_the_above_question, form_id: form.id }
      let(:answer_settings) do
        {
          only_one_option: "true",
          selection_options: [{ name: "Option 1", value: "option 1" }, { name: "Option 2", value: "option 2" }],
          none_of_the_above_question: {
            question_text: "Enter your own option",
            is_optional: "true",
          },
        }
      end

      it "the welsh answer_settings include blank none of the above question" do
        page = question_input.submit
        expect(page.answer_settings_cy.as_json).to eq({
          "only_one_option" => "true",
          "selection_options" => [
            { "name" => "", "value" => "option 1" },
            { "name" => "", "value" => "option 2" },
          ],
          "none_of_the_above_question" => {
            "question_text" => "",
            "is_optional" => "true",
          },
        })
      end
    end
  end

  describe "#update_page", feature_multiple_branches: false do
    let(:page) { create(:page, form:) }

    it "returns false if the form is invalid" do
      allow(question_input).to receive(:invalid?).and_return(true)
      expect(question_input.update_page(page)).to be false
    end

    context "when form is valid" do
      before do
        question_input.question_text = "How old are you?"
        question_input.hint_text = "As a number"
        question_input.is_optional = "false"
        question_input.is_repeatable = "true"
        question_input.update_page(page)
      end

      it "sets a draft_question question_text" do
        expect(question_input.draft_question.question_text).to eq question_input.question_text
      end

      it "sets a draft_question hint_text" do
        expect(question_input.draft_question.hint_text).to eq question_input.hint_text
      end

      it "sets a draft_question is_optional" do
        expect(question_input.draft_question.is_optional.to_s).to eq question_input.is_optional
      end

      it "sets a draft_question is_repeatable" do
        expect(question_input.draft_question.is_repeatable.to_s).to eq question_input.is_repeatable
      end

      it "updates the page attributes" do
        page.reload
        expect(page.question_text).to eq question_input.question_text
        expect(page.hint_text).to eq question_input.hint_text
        expect(page.is_optional.to_s).to eq question_input.is_optional
        expect(page.is_repeatable.to_s).to eq question_input.is_repeatable
        expect(page.answer_settings).to eq DataStruct.recursive_new(question_input.answer_settings)
        expect(page.page_heading).to eq question_input.page_heading
        expect(page.guidance_markdown).to eq question_input.guidance_markdown
        expect(page.answer_type).to eq question_input.answer_type
      end

      it "does not change the answer_settings_cy" do
        expect(page.answer_settings_cy).to be_nil
      end

      context "when the answer_settings has an empty hash for none_of_the_above_question" do
        let(:answer_settings) { { foo: "bar", none_of_the_above_question: {} } }

        it "removes the empty hash from the answer_settings" do
          expect(page.reload.answer_settings).to eq DataStruct.recursive_new({ "foo": "bar" })
        end
      end

      context "when the answer_settings has popolated none_of_the_above_question" do
        let(:answer_settings) { { foo: "bar", none_of_the_above_question: { "question_text": "Enter something" } } }

        it "keeps the populated none_of_the_above_question in the answer_settings" do
          expect(page.reload.answer_settings).to eq DataStruct.recursive_new({ "foo": "bar", "none_of_the_above_question": { "question_text": "Enter something" } })
        end
      end

      context "when the page has selection options and no Welsh translation" do
        let(:draft_question) { build :selection_draft_question, form_id: form.id }
        let(:answer_settings) { { selection_options: [{ name: "Option 1", value: "Option 1" }, { name: "Option 2", value: "Option 2" }] } }

        it "welsh answer_settings is nil" do
          expect(page.answer_settings_cy.as_json).to be_nil
        end
      end

      context "when the form has a Welsh translation" do
        let(:form) { create :form, available_languages: %w[en cy] }

        context "and the page has selection options but no Welsh options yet" do
          let(:draft_question) { build :selection_draft_question, form_id: form.id }
          let(:answer_settings) { { selection_options: [{ name: "Option 1", value: "Option 1" }, { name: "Option 2", value: "Option 2" }] } }

          it "adds the welsh answer_settings" do
            expect(page.answer_settings_cy.as_json).to eq({ "selection_options" => [{ "name" => "", "value" => "Option 1" }, { "name" => "", "value" => "Option 2" }] })
          end
        end

        context "and the page has selection options and existing Welsh options" do
          let(:draft_question) { build :selection_draft_question, form_id: form.id }
          let(:answer_settings) { { selection_options: [{ name: "Option 1", value: "Option 1" }, { name: "Option 2", value: "Option 2" }] } }
          let(:page) { create(:page, form:, answer_settings_cy: { selection_options: [{ name: "Yes", value: "Yes" }, { name: "No", value: "No" }] }) }

          it "keeps the welsh text but updates the new values" do
            expect(page.answer_settings_cy.as_json).to eq({ "selection_options" => [{ "name" => "Yes", "value" => "Option 1" }, { "name" => "No", "value" => "Option 2" }] })
          end
        end

        context "and the page has selection options with none of the above" do
          let(:draft_question) { build :selection_draft_question, :with_optional_none_of_the_above_question, form_id: form.id }
          let(:answer_settings) do
            {
              only_one_option: "true",
              selection_options: [
                { name: "Option 1", value: "Option 1" },
                { name: "Option 2", value: "Option 2" },
              ],
              none_of_the_above_question: {
                question_text: "Enter your own option",
                is_optional: "true",
              },
            }
          end

          it "the welsh answer_settings include blank none of the above question" do
            expect(page.answer_settings_cy.none_of_the_above_question.question_text).to eq("")
          end

          context "with existing Welsh text" do
            let(:page) do
              create(:page,
                     form:,
                     answer_settings_cy: {
                       selection_options: [
                         { name: "Welsh option 1", value: "Option 1" },
                         { name: "Welsh option 2", value: "Option 2" },
                       ],
                       none_of_the_above_question: {
                         question_text: "Welsh none of the above question?",
                       },
                     })
            end

            it "uses the welsh text for none of the above question" do
              expect(page.answer_settings_cy.none_of_the_above_question.question_text).to eq("Welsh none of the above question?")
            end
          end
        end
      end
    end

    context "when there are conditions which no longer have answer_values" do
      let(:draft_question) { build :selection_draft_question, form_id: form.id }
      let(:answer_settings) { { only_one_option: "true", selection_options: [{ name: "Option 1", value: "Option 1" }, { name: "Not option 2", value: "Not option 2" }] } }

      let!(:keep_condition) { create(:condition, answer_value: "Option 1", routing_page_id: page.id) }
      let!(:remove_condition) { create(:condition, answer_value: "Option 2", routing_page_id: page.id) }

      context "when the form has multiple branches enabled", :feature_multiple_branches do
        it "removes the conditions" do
          expect { question_input.update_page(page) }.to change { page.routing_conditions.count }.from(2).to(1)
          expect(Condition.exists?(keep_condition.id)).to be true
          expect(Condition.exists?(remove_condition.id)).to be false
        end
      end

      context "when the form has multiple branches disabled" do
        let(:form) { create :form, :with_group, group: create(:group, multiple_branches_enabled: false) }

        it "does not remove the conditions" do
          expect { question_input.update_page(page) }.not_to change { page.routing_conditions.count }.from(2)
        end
      end
    end

    context "when there are conditions based on the none of the above option" do
      # The draft question before we update it
      # It's optional so there is a none of the above option
      let(:draft_question) { build :selection_draft_question, form_id: form.id, is_optional: true }

      # The settings we are saving to the page
      let(:answer_settings) { { only_one_option: "true", selection_options: [{ name: "Option 1", value: "Option 1" }, { name: "Option 2", value: "Option 2" }] } }

      # Is optional is a string here because it comes from the form
      # We set it to false, simulating remove the none of the above option
      let(:is_optional) { "false" }

      let!(:none_of_the_above_condition) { create(:condition, answer_value: Condition::NONE_OF_THE_ABOVE, routing_page_id: page.id) }
      let!(:other_condition) { create(:condition, answer_value: "Option 2", routing_page_id: page.id) }

      context "when the form has multiple branches enabled", :feature_multiple_branches do
        it "removes the none of the above condition" do
          expect { question_input.update_page(page) }.to change { page.routing_conditions.count }.from(2).to(1)
          expect(Condition.exists?(none_of_the_above_condition.id)).to be false
          expect(Condition.exists?(other_condition.id)).to be true
        end
      end

      context "when the form has multiple branches disabled", feature_multiple_branches: false do
        it "does not remove the none of the above condition" do
          expect { question_input.update_page(page) }.not_to change { page.routing_conditions.count }.from(2)
        end
      end
    end

    context "when the original question is being changed to a selection question and has a condition" do
      let(:answer_type) { "selection" }
      let(:answer_settings) { { only_one_option: "true", selection_options: [{ name: "Option 1", value: "Option 1" }, { name: "Option 2", value: "Option 2" }] } }
      let!(:condition) { create(:condition, routing_page_id: page.id) }

      context "when the form has multiple branches enabled", :feature_multiple_branches do
        it "creates a condition for each option" do
          expect { question_input.update_page(page) }.to change { page.routing_conditions.count }.from(1).to(2)

          expect(Condition.where(answer_value: "Option 1", routing_page_id: page.id).exists?).to be true
          expect(Condition.where(answer_value: "Option 2", routing_page_id: page.id).exists?).to be true

          expect(Condition.exists?(condition.id)).to be false
        end

        context "when the question is optional" do
          let(:is_optional) { "true" }

          it "creates a condition for each option and none of the above" do
            expect { question_input.update_page(page) }.to change { page.routing_conditions.count }.from(1).to(3)

            expect(Condition.where(answer_value: Condition::NONE_OF_THE_ABOVE).exists?).to be true

            expect(Condition.exists?(condition.id)).to be false
          end
        end

        context "when the original condition skips to the end of the form" do
          let!(:condition) { create(:condition, routing_page: page, skip_to_end: true) }

          it "creates a condition for each option which skips to the end" do
            expect { question_input.update_page(page) }.to change { page.routing_conditions.count }.from(1).to(2)

            expect(Condition.where(answer_value: "Option 1", routing_page_id: page.id, skip_to_end: true, goto_page_id: nil).exists?).to be true

            expect(Condition.exists?(condition.id)).to be false
          end
        end
      end

      context "when the form does not have multiple branches enabled", feature_multiple_branches: false do
        it "does not create a condition for each option or remove the original condition" do
          expect { question_input.update_page(page) }.not_to change { page.routing_conditions.count }.from(1)
          expect(Condition.exists?(condition.id)).to be true
        end
      end
    end
  end

  describe "#update_draft_question!" do
    let(:question_input) { build :question_input, question_text:, hint_text:, is_optional: "true", is_repeatable: "false", draft_question: }
    let(:hint_text) { "Enter your full name as it appears in your passport" }
    let(:draft_question) { create :draft_question_for_new_page }

    it "updates the draft_question attributes" do
      question_input.update_draft_question!
      expect(draft_question.reload).to have_attributes(
        question_text:,
        hint_text:,
        is_optional: true,
        is_repeatable: false,
      )
    end
  end
end
