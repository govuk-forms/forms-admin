require "rails_helper"

RSpec.describe Pages::ConditionsInput, type: :model do
  let(:conditions_input) { described_class.new(form:, page:, record: condition) }
  let(:form) { create :form, :ready_for_routing }
  let(:pages) { form.pages }
  let(:is_optional) { false }
  let(:page) do
    pages.second.tap do |second_page|
      second_page.is_optional = is_optional
      second_page.answer_type = "selection"
      second_page.answer_settings = DataStruct.new(
        only_one_option: true,
        selection_options: [DataStruct.new({ name: "Option 1" }), DataStruct.new({ name: "Option 2" })],
      )
    end
  end
  let(:condition) { nil }

  describe "validations" do
    it "is valid given valid params" do
      conditions_input.goto_page_id = page.id
      conditions_input.answer_value = "Rabbit"
      expect(conditions_input).to be_valid
    end

    %w[end_of_form exit_page].each do |goto_page_id|
      it "is valid when the goto_page_id is #{goto_page_id}" do
        conditions_input.goto_page_id = goto_page_id
        conditions_input.answer_value = "Rabbit"
        expect(conditions_input).to be_valid
      end
    end

    it "is invalid if answer_value is nil" do
      error_message = I18n.t("activemodel.errors.models.pages/conditions_input.attributes.answer_value.blank")
      conditions_input.answer_value = nil
      expect(conditions_input).to be_invalid
      expect(conditions_input.errors.full_messages_for(:answer_value)).to include("Answer value #{error_message}")
    end

    it "is invalid if goto_page_id is nil" do
      error_message = I18n.t("activemodel.errors.models.pages/conditions_input.attributes.goto_page_id.blank")
      conditions_input.goto_page_id = nil
      expect(conditions_input).to be_invalid
      expect(conditions_input.errors.full_messages_for(:goto_page_id)).to include("Goto page #{error_message}")
    end

    it "is invalid when the goto_page_id is not a page ID or end_of_form" do
      error_message = I18n.t("activemodel.errors.models.pages/conditions_input.attributes.goto_page_id.invalid")
      conditions_input.goto_page_id = "invalid_page_id"
      expect(conditions_input).to be_invalid
      expect(conditions_input.errors.full_messages_for(:goto_page_id)).to include("Goto page #{error_message}")
    end
  end

  describe "#submit" do
    context "when validation pass" do
      before do
        conditions_input.answer_value = "Rabbit"
        conditions_input.goto_page_id = pages.last.id
      end

      it "calls assign_skip_to_end" do
        allow(conditions_input).to receive(:assign_skip_to_end)
        conditions_input.submit

        expect(conditions_input).to have_received(:assign_skip_to_end).exactly(1).times
      end

      it "creates a condition" do
        expect {
          conditions_input.submit
        }.to change(Condition, :count).by(1)
      end
    end

    context "when validations fail" do
      it "returns false" do
        invalid_conditions_input = described_class.new
        expect(invalid_conditions_input.submit).to be false
      end
    end
  end

  describe "#update_condition" do
    context "when validation pass" do
      let(:condition) { create :condition, routing_page_id: page.id, check_page_id: page.id, answer_value: "Wales", goto_page_id: pages.third.id }

      before do
        conditions_input.answer_value = "England"
        conditions_input.goto_page_id = pages.fourth.id
      end

      it "updates the condition" do
        expect {
          conditions_input.update_condition
        }.to change { condition.reload.answer_value }.to("England")
      end
    end

    context "when going to an exit page" do
      it "does not call assign_skip_to_end" do
        allow(conditions_input).to receive(:assign_skip_to_end)

        conditions_input.goto_page_id = "exit_page"
        conditions_input.update_condition

        expect(conditions_input).not_to have_received(:assign_skip_to_end)
      end
    end

    context "when validations fail" do
      it "returns false" do
        invalid_conditions_input = described_class.new
        expect(invalid_conditions_input.update_condition).to be false
      end
    end
  end

  describe "#routing_answer_options" do
    it "returns a list of answers for the given page" do
      result = conditions_input.routing_answer_options
      expect(result).to eq([
        OpenStruct.new(value: "Option 1", label: "Option 1"),
        OpenStruct.new(value: "Option 2", label: "Option 2"),
      ])
    end

    context "when selection setting includes 'none of the above'" do
      let(:is_optional) { true }

      it "adds extra 'None of above' options to the end" do
        result = conditions_input.routing_answer_options
        expect(result).to eq([
          OpenStruct.new(value: "Option 1", label: "Option 1"),
          OpenStruct.new(value: "Option 2", label: "Option 2"),
          OpenStruct.new(value: Condition::NONE_OF_THE_ABOVE,
                         label: I18n.t("page_conditions.none_of_the_above")),
        ])
      end
    end
  end

  describe "#goto_page_options" do
    context "when routing from the first form page" do
      subject(:goto_page_options) { described_class.new(form:, page: pages.first).goto_page_options }

      it "returns a list of pages" do
        expect(goto_page_options).to all have_attributes(id: a_value, question_text: a_kind_of(String))
      end

      it "excludes the first page and the page straight after the first page" do
        expect(goto_page_options).not_to include(
          *form.pages.take(2).map { |p| OpenStruct.new(id: p.id, question_text: "#{p.position}. #{p.question_text}") },
        )
      end

      it "includes all pages after the page straight after the first page" do
        expect(goto_page_options).to start_with(
          *form.pages.drop(2).map { |p| OpenStruct.new(id: p.id, question_text: "#{p.position}. #{p.question_text}") },
        )
      end

      it "includes 'Check your answers before submitting'" do
        expect(goto_page_options).to include(
          OpenStruct.new(id: "end_of_form", question_text: I18n.t("page_conditions.end_of_form")),
        )
      end
    end

    context "when routing from the third form page" do
      subject(:goto_page_options) { described_class.new(form:, page: pages[routing_from_page_count - 1]).goto_page_options }

      let(:routing_from_page_count) { 2 }

      it "returns a list of pages" do
        expect(goto_page_options).to all have_attributes(id: a_value, question_text: a_kind_of(String))
      end

      it "excludes any pages before the given page and the page straight after the given page" do
        expect(goto_page_options).not_to include(
          *form.pages.take(routing_from_page_count + 1).map { |p| OpenStruct.new(id: p.id, question_text: "#{p.position}. #{p.question_text}") },
        )
      end

      it "includes all pages after the page after the given page" do
        expect(goto_page_options).to start_with(
          *form.pages.drop(routing_from_page_count + 1).map { |p| OpenStruct.new(id: p.id, question_text: "#{p.position}. #{p.question_text}") },
        )
      end

      it "includes 'Check your answers before submitting'" do
        expect(goto_page_options).to include(
          OpenStruct.new(id: "end_of_form", question_text: I18n.t("page_conditions.end_of_form")),
        )
      end
    end
  end

  describe "#check_errors_from_api" do
    let(:condition) { create :condition, routing_page_id: page.id, answer_value: "England", check_page_id: page.id, goto_page_id: pages.third.id }

    it "is invalid if there are validation errors" do
      error_message = I18n.t("activemodel.errors.models.pages/conditions_input.attributes.answer_value.answer_value_doesnt_exist")
      conditions_input.check_errors_from_api
      expect(conditions_input.errors.full_messages_for(:answer_value)).to include("Answer value #{error_message}")
    end
  end

  describe "#assign_condition_values" do
    let(:conditions_input) { described_class.new(form:, page:, record: condition, answer_value: condition.answer_value, goto_page_id: condition.goto_page_id, skip_to_end: condition.skip_to_end) }
    let(:condition) { create :condition, routing_page_id: page.id, answer_value: "England", check_page_id: page.id, goto_page_id:, skip_to_end: }
    let(:goto_page_id) { nil }
    let(:skip_to_end) { false }

    context "when goto_page is nil and skip_to_end is set to true" do
      let(:skip_to_end) { true }

      it "sets goto_page_id to 'end_of_form'" do
        conditions_input.assign_condition_values
        expect(conditions_input.goto_page_id).to eq "end_of_form"
      end
    end

    context "when goto_page is nil and skip_to_end is set to false" do
      it "sets goto_page_id to 'end_of_form'" do
        conditions_input.assign_condition_values
        expect(conditions_input.goto_page_id).to be_nil
      end
    end

    context "when goto_page is not nil" do
      let(:goto_page_id) { 3 }
      let(:skip_to_end) { true }

      it "sets goto_page_id to 'end_of_form'" do
        conditions_input.assign_condition_values
        expect(conditions_input.goto_page_id).to eq 3
      end
    end

    context "when exit_page? is true" do
      let(:condition) { build :condition, :with_exit_page }

      it "sets goto_page_id to 'exit_page'" do
        conditions_input.assign_condition_values
        expect(conditions_input.goto_page_id).to eq "exit_page"
      end
    end
  end

  describe "#assign_skip_to_end" do
    let(:conditions_input) { described_class.new(form:, page:, goto_page_id:, skip_to_end:) }
    let(:goto_page_id) { 3 }
    let(:skip_to_end) { false }

    context "when goto_page is 'end_of_form" do
      let(:goto_page_id) { "end_of_form" }

      it "sets goto_page_id to nil and skip_to_end to true" do
        conditions_input.assign_skip_to_end
        expect(conditions_input.goto_page_id).to be_nil
        expect(conditions_input.skip_to_end).to be true
      end
    end

    context "when goto_page is not 'end_of_form" do
      let(:goto_page_id) { 3 }
      let(:skip_to_end) { true }

      it "does not change goto_page_id and sets skip_to_end to false" do
        conditions_input.assign_skip_to_end
        expect(conditions_input.goto_page_id).to eq 3
        expect(conditions_input.skip_to_end).to be false
      end
    end
  end

  describe "#secondary_skip?" do
    let(:page_routes_service) { instance_double(PageRoutesService) }

    before do
      page.reload
    end

    context "when the page has a secondary skip condition" do
      let(:condition) { create :condition, routing_page_id: pages.first.id, check_page_id: page.id, goto_page_id: pages.fourth.id }

      it "is true" do
        expect(conditions_input.secondary_skip?).to be true
      end
    end

    context "when the page does not have a secondary skip condition" do
      let(:condition) { create :condition, routing_page_id: page.id, check_page_id: page.id, answer_value: "England", goto_page_id: pages.fourth.id }

      it "is false" do
        expect(conditions_input.secondary_skip?).to be false
      end
    end
  end
end
