require "rails_helper"

RSpec.describe Pages::ExitPageInput, type: :model do
  subject(:exit_page_input) { described_class.new(heading:, markdown:) }

  let(:heading) { "the heading" }
  let(:markdown) { "some markdown" }

  describe "validations" do
    it "is invalid if heading is nil" do
      error_message = I18n.t("activemodel.errors.models.pages/exit_page_input.attributes.heading.blank")
      exit_page_input.heading = nil
      expect(exit_page_input).to be_invalid
      expect(exit_page_input.errors.full_messages_for(:heading)).to include("Heading #{error_message}")
    end

    it "is invalid if markdown is nil" do
      error_message = I18n.t("activemodel.errors.models.pages/exit_page_input.attributes.markdown.blank")
      exit_page_input.markdown = nil
      expect(exit_page_input).to be_invalid
      expect(exit_page_input.errors.full_messages_for(:markdown)).to include("Markdown #{error_message}")
    end

    it "is invalid if heading is too long" do
      error_message = I18n.t("activemodel.errors.models.pages/exit_page_input.attributes.heading.too_long", count: 250)
      exit_page_input.heading = "a" * 251
      expect(exit_page_input).to be_invalid
      expect(exit_page_input.errors.full_messages_for(:heading)).to include("Heading #{error_message}")
    end

    it_behaves_like "a markdown field with headings allowed", :mark_complete do
      let(:model) { exit_page_input }
      let(:attribute) { :markdown }
    end
  end

  describe "#submit" do
    subject(:exit_page_input) { described_class.new(heading:, markdown:, page:) }

    let(:heading) { "the heading" }
    let(:markdown) { "some markdown" }
    let(:page) { create :page }

    it "returns a truthy value" do
      expect(exit_page_input.submit).to be_truthy
    end

    it "creates an exit page" do
      expect {
        exit_page_input.submit
      }.to change(ExitPage, :count).by(1)

      expect(page.exit_pages.first.question_page).to eq(page)
      expect(page.exit_pages.first.heading).to eq(heading)
      expect(page.exit_pages.first.markdown).to eq(markdown)
    end

    context "when the exit page is invalid" do
      let(:heading) { nil }

      it "returns false" do
        expect(exit_page_input.submit).to be false
      end
    end
  end
end
