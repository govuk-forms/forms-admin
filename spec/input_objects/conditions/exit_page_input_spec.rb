require "rails_helper"

RSpec.describe Conditions::ExitPageInput, type: :model do
  let(:exit_page_input) { described_class.new(form:, page:, answer_value:) }
  let(:form) { create :form, :ready_for_routing }
  let(:pages) { form.pages }
  let(:answer_value) { nil }
  let(:page) do
    pages.second.tap do |second_page|
      second_page.is_optional = false
      second_page.answer_type = "selection"
      second_page.answer_settings = DataStruct.new(
        only_one_option: true,
        selection_options: [OpenStruct.new(attributes: { name: "Option 1" }), OpenStruct.new(attributes: { name: "Option 2" })],
      )
    end
  end

  describe "validations" do
    it "is invalid if answer_value is nil" do
      error_message = I18n.t("activemodel.errors.models.conditions/exit_page_input.attributes.answer_value.blank")
      exit_page_input.answer_value = nil
      expect(exit_page_input).to be_invalid
      expect(exit_page_input.errors.full_messages_for(:answer_value)).to include("Answer value #{error_message}")
    end

    it "is invalid if exit_page_heading is nil" do
      error_message = I18n.t("activemodel.errors.models.conditions/exit_page_input.attributes.exit_page_heading.blank")
      exit_page_input.exit_page_heading = nil
      expect(exit_page_input).to be_invalid
      expect(exit_page_input.errors.full_messages_for(:exit_page_heading)).to include("Exit page heading #{error_message}")
    end

    it "is invalid if exit_page_markdown is nil" do
      error_message = I18n.t("activemodel.errors.models.conditions/exit_page_input.attributes.exit_page_markdown.blank")
      exit_page_input.exit_page_markdown = nil
      expect(exit_page_input).to be_invalid
      expect(exit_page_input.errors.full_messages_for(:exit_page_markdown)).to include("Exit page markdown #{error_message}")
    end

    it "is invalid if exit_page_heading is too long" do
      error_message = I18n.t("activemodel.errors.models.conditions/exit_page_input.attributes.exit_page_heading.too_long")
      exit_page_input.exit_page_heading = "a" * 5000
      expect(exit_page_input).to be_invalid
      expect(exit_page_input.errors.full_messages_for(:exit_page_heading)).to include("Exit page heading #{error_message}")
    end

    it "in invalid if exit_page_markdown is too long" do
      error_message = I18n.t("activemodel.errors.models.conditions/exit_page_input.attributes.exit_page_markdown.too_long")
      exit_page_input.exit_page_markdown = "a" * 5000
      expect(exit_page_input).to be_invalid
      expect(exit_page_input.errors.full_messages_for(:exit_page_markdown)).to include("Exit page markdown #{error_message}")
    end
  end

  describe "#submit" do
    context "when validation pass" do
      before do
        exit_page_input.answer_value = "Frog"
        exit_page_input.exit_page_markdown = "You have selected an amphibian"
        exit_page_input.exit_page_heading = "You need to request anything other than an amphibian to use this service"
      end

      it "creates a condition" do
        expect {
          exit_page_input.submit
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
end
