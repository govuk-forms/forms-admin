require "rails_helper"

RSpec.describe FormDocument::Step, type: :model do
  subject(:form_document_step) { described_class.new(page_as_form_document_step) }

  let(:page) { create :page }
  let(:next_page) { create :page }
  let(:page_as_form_document_step) { page.as_form_document_step(next_page) }

  it "ignores any attributes that are not defined" do
    expect(described_class.new(foo: "bar").attributes).not_to include(:foo)
  end

  it "has the ID, position and next page ID from the form_document_step" do
    expect(form_document_step).to have_attributes(
      id: page.external_id,
      position: page.position,
      next_step_id: next_page.external_id,
    )
  end

  it "has all question attributes the original page has" do
    expect(form_document_step.data).to have_attributes(
      answer_type: page.answer_type,
      answer_settings: page.answer_settings,
      question_text: page.question_text,
      hint_text: page.hint_text,
      page_heading: page.page_heading,
      guidance_markdown: page.guidance_markdown,
      is_optional: page.is_optional,
      is_repeatable: page.is_repeatable,
    )
  end

  describe "#is_optional?" do
    [
      { input: true, result: true },
      { input: "true", result: true },
      { input: false, result: false },
      { input: "false", result: false },
      { input: "0", result: false },
      { input: nil, result: false },
    ].each do |scenario|
      it "returns #{scenario[:result]} when is_optional is #{scenario[:input]}" do
        step = described_class.new("data" => { "is_optional" => scenario[:input] })
        expect(step.is_optional?).to eq scenario[:result]
      end
    end
  end

  describe "#is_repeatable?" do
    [
      { input: true, result: true },
      { input: "true", result: true },
      { input: false, result: false },
      { input: "false", result: false },
      { input: "0", result: false },
      { input: nil, result: false },
    ].each do |scenario|
      it "returns #{scenario[:result]} when is_repeatable is #{scenario[:input]}" do
        step = described_class.new("data" => { "is_repeatable" => scenario[:input] })
        expect(step.is_repeatable?).to eq scenario[:result]
      end
    end
  end

  describe "#routing_conditions" do
    it "defaults to an empty array" do
      expect(described_class.new).to have_attributes(routing_conditions: [])
    end

    it "converts attributes for routing conditions to a model" do
      routing_condition_attributes = attributes_for :condition
      step = described_class.new("routing_conditions" => [routing_condition_attributes])
      expect(step.routing_conditions).to all be_a FormDocument::Condition
    end
  end

  describe "#exit_pages" do
    it "defaults to an empty array" do
      expect(described_class.new).to have_attributes(exit_pages: [])
    end

    it "converts attributes for exit pages to a model" do
      exit_page_attributes = attributes_for :exit_page
      step = described_class.new("exit_pages" => [exit_page_attributes])
      expect(step.exit_pages).to all be_a FormDocument::ExitPage
    end
  end
end
