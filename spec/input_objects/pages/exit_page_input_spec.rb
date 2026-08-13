require "rails_helper"

RSpec.describe Pages::ExitPageInput, type: :model do
  subject(:exit_page_input) { described_class.new(heading:, markdown:) }

  let(:heading) { "the heading" }
  let(:markdown) { "some markdown" }

  it_behaves_like "validates exit pages" do
    let(:model) { exit_page_input }
  end

  describe "#submit" do
    subject(:exit_page_input) { described_class.new(heading:, markdown:, page:) }

    let(:heading) { "the heading" }
    let(:markdown) { "some markdown" }
    let(:page) { create :page }
    let(:form) { page.form }

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
