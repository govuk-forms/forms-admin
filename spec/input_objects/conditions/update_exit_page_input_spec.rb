require "rails_helper"

RSpec.describe Conditions::UpdateExitPageInput, type: :model do
  let(:update_exit_page_input) { described_class.new(form:, page:, record: condition) }
  let(:form) { create :form, :ready_for_routing }
  let(:page) { form.pages.first }
  let(:condition) { create :condition, :with_exit_page, routing_page_id: page.id, check_page_id: page.id }

  describe "validations" do
    it "is invalid if exit_page_heading is nil" do
      error_message = I18n.t("activemodel.errors.models.conditions/exit_page_input.attributes.exit_page_heading.blank")
      update_exit_page_input.exit_page_heading = nil
      expect(update_exit_page_input).to be_invalid
      expect(update_exit_page_input.errors.full_messages_for(:exit_page_heading)).to include("Exit page heading #{error_message}")
    end

    it "is invalid if exit_page_markdown is nil" do
      error_message = I18n.t("activemodel.errors.models.conditions/update_exit_page_input.attributes.exit_page_markdown.blank")
      update_exit_page_input.exit_page_markdown = nil
      expect(update_exit_page_input).to be_invalid
      expect(update_exit_page_input.errors.full_messages_for(:exit_page_markdown)).to include("Exit page markdown #{error_message}")
    end

    it "is invalid if exit_page_heading is too long" do
      error_message = I18n.t("activemodel.errors.models.conditions/update_exit_page_input.attributes.exit_page_heading.too_long")
      update_exit_page_input.exit_page_heading = "a" * 5000
      expect(update_exit_page_input).to be_invalid
      expect(update_exit_page_input.errors.full_messages_for(:exit_page_heading)).to include("Exit page heading #{error_message}")
    end

    it "is invalid if exit_page_markdown is too long" do
      error_message = I18n.t("activemodel.errors.models.conditions/update_exit_page_input.attributes.exit_page_markdown.too_long")
      update_exit_page_input.exit_page_markdown = "a" * 5000
      expect(update_exit_page_input).to be_invalid
      expect(update_exit_page_input.errors.full_messages_for(:exit_page_markdown)).to include("Exit page markdown #{error_message}")
    end
  end

  describe "#submit" do
    context "when validation pass" do
      before do
        update_exit_page_input.exit_page_heading = "New exit page heading"
        update_exit_page_input.exit_page_markdown = "New exit page markdown"
      end

      it "saves the condition" do
        expect {
          update_exit_page_input.submit
        }.to change { condition.reload.exit_page_heading }.to("New exit page heading")
      end
    end

    context "when the exit page has been edited directly" do
      before do
        condition.exit_page.update!(heading: "Edited heading", markdown: "Edited markdown")
        condition.reload
      end

      it "updates the exit page when the values match the condition's out of date copy" do
        update_exit_page_input.exit_page_heading = "Exit page heading"
        update_exit_page_input.exit_page_markdown = "Exit page markdown"

        expect(update_exit_page_input.submit).to be_truthy
        expect(condition.exit_page.reload).to have_attributes(heading: "Exit page heading", markdown: "Exit page markdown")
      end

      it "updates the exit page when only one value matches the condition's out of date copy" do
        update_exit_page_input.exit_page_heading = "Exit page heading"
        update_exit_page_input.exit_page_markdown = "Another markdown"

        expect(update_exit_page_input.submit).to be_truthy
        expect(condition.exit_page.reload).to have_attributes(heading: "Exit page heading", markdown: "Another markdown")
      end

      it "does not remove the Welsh translations" do
        condition.exit_page.update!(heading_cy: "Welsh heading", markdown_cy: "Welsh markdown")
        update_exit_page_input.exit_page_heading = "Exit page heading"
        update_exit_page_input.exit_page_markdown = "Exit page markdown"

        update_exit_page_input.submit

        expect(condition.exit_page.reload).to have_attributes(heading_cy: "Welsh heading", markdown_cy: "Welsh markdown")
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
