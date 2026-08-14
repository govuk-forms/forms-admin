require "rails_helper"

RSpec.describe Pages::UpdateExitPageInput, type: :model do
  subject(:exit_page_input) { described_class.new(heading:, markdown:) }

  let(:heading) { "the heading" }
  let(:markdown) { "some markdown" }

  it_behaves_like "validates exit pages" do
    let(:model) { exit_page_input }
  end

  describe "#submit" do
    subject(:exit_page_input) { described_class.new(heading:, markdown:, page:, exit_page:) }

    let(:heading) { "the heading" }
    let(:markdown) { "some markdown" }
    let(:form) { page.form }
    let(:page) { create :page }
    let(:exit_page) { create :exit_page, question_page: page }

    it "returns a truthy value" do
      expect(exit_page_input.submit).to be_truthy
    end

    it "updates the exit page" do
      exit_page_input.submit
      expect(exit_page.question_page).to eq(page)
      expect(exit_page.heading).to eq(heading)
      expect(exit_page.markdown).to eq(markdown)
    end

    it "sets question_section_completed to false and updates the draft" do
      form.question_section_completed = true
      expect { exit_page_input.submit }.to change(form, :question_section_completed).from(true).to(false)
        .and(change { form.draft_form_document.reload.updated_at })
    end

    context "when the exit page is invalid" do
      let(:heading) { nil }

      it "returns false" do
        expect(exit_page_input.submit).to be false
      end
    end
  end
end
