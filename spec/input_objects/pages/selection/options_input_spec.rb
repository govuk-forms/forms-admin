require "rails_helper"

RSpec.describe Pages::Selection::OptionsInput do
  subject(:input) { described_class.new(draft_question:, include_none_of_the_above:, selection_options:) }

  let(:form) { create :form }
  let(:only_one_option) { "true" }
  let(:answer_settings) { { only_one_option: } }
  let(:is_optional) { nil }
  let(:draft_question) { build :draft_question, answer_type: "selection", answer_settings:, form_id: form.id, is_optional: }
  let(:selection_options) { [{ name: "option 1" }, { name: "option 2" }] }
  let(:include_none_of_the_above) { "yes" }

  describe "validations" do
    describe "include_none_of_the_above" do
      it "is invalid if include_none_of_the_above is blank" do
        input = described_class.new(draft_question:, include_none_of_the_above: nil, selection_options:)
        expect(input).not_to be_valid
        expected_message = I18n.t("activemodel.errors.models.pages/selection/options_input.attributes.include_none_of_the_above.inclusion")
        expect(input.errors.full_messages_for(:include_none_of_the_above)).to include("Include none of the above #{expected_message}")
      end

      it "is invalid if include_none_of_the_above value is not in allowed values" do
        input = described_class.new(draft_question:, include_none_of_the_above: "foo", selection_options:)
        expect(input).not_to be_valid
        expected_message = I18n.t("activemodel.errors.models.pages/selection/options_input.attributes.include_none_of_the_above.inclusion")
        expect(input.errors.full_messages_for(:include_none_of_the_above)).to include("Include none of the above #{expected_message}")
      end

      it "is valid if include_none_of_the_above is yes" do
        expect(input).to be_valid
      end

      it "is valid if include_none_of_the_above is yes_with_question" do
        input = described_class.new(draft_question:, include_none_of_the_above: "yes_with_question", selection_options:)
        expect(input).to be_valid
      end

      it "is valid if include_none_of_the_above is no" do
        input = described_class.new(draft_question:, include_none_of_the_above: "no", selection_options:)
        expect(input).to be_valid
      end
    end

    describe "selection_options" do
      it "is invalid if fewer than 2 selection options are provided" do
        input.selection_options = []
        error_message = I18n.t("activemodel.errors.models.pages/selection/options_input.attributes.selection_options.minimum")
        expect(input).not_to be_valid

        expect(input.errors.full_messages_for(:selection_options)).to include("Selection options #{error_message}")
      end

      it "is invalid if selection options are not unique" do
        input.selection_options = [{ name: "option 1" }, { name: "option 2" }, { name: "option 1" }]
        error_message = I18n.t("activemodel.errors.models.pages/selection/options_input.attributes.selection_options.uniqueness")
        expect(input).not_to be_valid

        expect(input.errors.full_messages_for(:selection_options)).to include("Selection options #{error_message}")
      end

      it "is valid if there are 2 unique selection values" do
        input.selection_options = (1..2).to_a.map { |i| { name: i.to_s } }

        expect(input).to be_valid
      end

      context "when only_one_option is true for the draft_question" do
        it "is invalid if more than 3000 selection options are provided" do
          input.selection_options = (1..3001).to_a.map { |i| OpenStruct.new(name: i.to_s) }
          error_message = I18n.t("activemodel.errors.models.pages/selection/options_input.attributes.selection_options.maximum_choose_only_one_option")
          expect(input).not_to be_valid

          expect(input.errors.full_messages_for(:selection_options)).to include("Selection options #{error_message}")
        end

        it "is valid if there are 3000 unique selection values" do
          input.selection_options = (1..3000).to_a.map { |i| { name: i.to_s } }

          expect(input).to be_valid
        end
      end

      context "when only_one_option is false for the draft_question" do
        let(:only_one_option) { "false" }

        it "is invalid if more than 30 selection options are provided" do
          input.selection_options = (1..31).to_a.map { |i| OpenStruct.new(name: i.to_s) }
          error_message = I18n.t("activemodel.errors.models.pages/selection/options_input.attributes.selection_options.maximum_choose_more_than_one_option")
          expect(input).not_to be_valid

          expect(input.errors.full_messages_for(:selection_options)).to include("Selection options #{error_message}")
        end

        it "is valid if there are 30 unique selection values" do
          input.selection_options = (1..30).to_a.map { |i| { name: i.to_s } }

          expect(input).to be_valid
        end
      end
    end
  end

  describe "#assign_form_values" do
    subject(:input) { described_class.new(draft_question:) }

    let(:answer_settings) do
      {
        selection_options: [{ name: "option 1" }, { name: "option 2" }],
        only_one_option: "true",
      }
    end

    before do
      input.assign_form_values
    end

    it "assigns selection_options from draft question answer_settings" do
      expect(input.selection_options.to_json).to eq([{ name: "option 1" }, { name: "option 2" }].to_json)
    end

    context "when is_optional is nil for the draft question" do
      let(:is_optional) { nil }

      it "assigns include_none_of_the_above to nil" do
        expect(input.include_none_of_the_above).to be_nil
      end
    end

    context "when is_optional is false for the draft question" do
      let(:is_optional) { false }

      it "assigns include_none_of_the_above to 'no'" do
        expect(input.include_none_of_the_above).to eq "no"
      end
    end

    context "when is_optional is true for the draft question" do
      let(:is_optional) { true }

      context "when the answer_settings does not contain none_of_the_above_question" do
        it "assigns include_none_of_the_above to 'yes'" do
          expect(input.include_none_of_the_above).to eq "yes"
        end
      end

      context "when the answer_settings contains none_of_the_above_question" do
        let(:answer_settings) do
          {
            selection_options: [{ name: "option 1" }, { name: "option 2" }],
            only_one_option: "true",
            none_of_the_above_question: { question_text: "Enter something" },
          }
        end

        it "assigns include_none_of_the_above to 'yes_with_question'" do
          expect(input.include_none_of_the_above).to eq "yes_with_question"
        end
      end
    end
  end

  describe "#submit" do
    it "returns false if the form is invalid" do
      input = described_class.new(draft_question:, include_none_of_the_above: nil, selection_options:)
      expect(input.submit).to be false
    end

    it "sets draft_question answer_settings and is_optional" do
      input.submit

      expect(input.draft_question.answer_settings).to include(selection_options: [{ name: "option 1", value: "option 1" }, { name: "option 2", value: "option 2" }])
    end

    it "sets draft_question is_optional" do
      expect { input.submit }.to change(draft_question, :is_optional).to true
    end

    it "logs submission" do
      allow(Rails.logger).to receive(:info)
      input.submit

      expect(Rails.logger).to have_received(:info).with("Submitted selection options for a selection question", {
        "is_bulk_entry": false,
        "options_count": 2,
        "only_one_option": true,
      })
    end

    context "when there are existing answer settings" do
      let(:answer_settings) { { foo: "bar" } }
      let(:include_none_of_the_above) { "yes" }

      before do
        draft_question.answer_settings = answer_settings
        input.submit
      end

      it "does not overwrite other answer_settings" do
        expect(draft_question.answer_settings).to include({ selection_options: [{ name: "option 1", value: "option 1" }, { name: "option 2", value: "option 2" }], foo: "bar" })
      end
    end
  end

  describe "#add_another" do
    it "adds an empty item to the end of the selection options array" do
      input.add_another

      expect(input.selection_options).to eq([{ name: "option 1" }, { name: "option 2" }, { name: "" }])
    end
  end

  describe "#remove" do
    it "removes the specified option from the selection options array" do
      input.remove(1)

      expect(input.selection_options.to_json).to eq([{ name: "option 1" }].to_json)
    end
  end

  describe "#filter_out_blank_options" do
    it "filters out blank inputs" do
      input.selection_options = [{ name: "1" }, { name: "" }, { name: "2" }]
      input.validate

      expect(input.selection_options.to_json).to eq([{ name: "1" }, { name: "2" }].to_json)
    end
  end

  it_behaves_like "base selection options input"

  describe "#can_add_more_options?" do
    context "when only_one_option is true for the draft_question" do
      let(:only_one_option) { "true" }

      context "and there are 3000 options" do
        let(:selection_options) { (1..3000).to_a.map { |i| OpenStruct.new(name: i.to_s) } }

        it "returns false" do
          expect(input.can_add_more_options?).to be false
        end
      end

      context "and there are fewer than 3000 options" do
        let(:selection_options) { (1..2999).to_a.map { |i| OpenStruct.new(name: i.to_s) } }

        it "returns true" do
          expect(input.can_add_more_options?).to be true
        end
      end
    end

    context "when only_one_option is false for the draft_question" do
      let(:only_one_option) { "false" }

      context "and there are 30 options" do
        let(:selection_options) { (1..30).to_a.map { |i| OpenStruct.new(name: i.to_s) } }

        it "returns false" do
          expect(input.can_add_more_options?).to be false
        end
      end

      context "and there are fewer than 30 options" do
        let(:selection_options) { (1..29).to_a.map { |i| OpenStruct.new(name: i.to_s) } }

        it "returns true" do
          expect(input.can_add_more_options?).to be true
        end
      end
    end
  end
end
