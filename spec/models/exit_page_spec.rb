require "rails_helper"

RSpec.describe ExitPage, type: :model do
  it "has a valid factory" do
    expect(build(:exit_page)).to be_valid
  end

  describe "validations" do
    context "when heading is blank" do
      it "is invalid" do
        expect(build(:exit_page, heading: nil)).not_to be_valid
      end
    end

    context "when markdown is blank" do
      it "is invalid" do
        expect(build(:exit_page, markdown: nil)).not_to be_valid
      end
    end
  end

  describe "associations" do
    let!(:question_page) { create(:page) }
    let!(:exit_page) { create(:exit_page, question_page:) }

    it "has a question page" do
      expect(exit_page.question_page).to eq(question_page)
    end

    it "is deleted when the question page is deleted" do
      expect { question_page.destroy! }.to change(described_class, :count).by(-1)
    end

    it "the page has exit pages" do
      expect(question_page.exit_pages).to eq([exit_page])
    end
  end

  describe "translations" do
    let!(:question_page) { create(:page) }
    let!(:exit_page) { create(:exit_page, question_page:) }

    it "can set and read translated attributes for :en and :cy locales" do
      exit_page.heading = "English heading"
      exit_page.markdown = "English markdown"

      exit_page.heading_cy = "Welsh heading"
      exit_page.markdown_cy = "Welsh markdown"
      exit_page.save!

      exit_page.reload
      expect(exit_page.heading).to eq("English heading")
      expect(exit_page.heading_cy).to eq("Welsh heading")

      expect(exit_page.markdown).to eq("English markdown")
      expect(exit_page.markdown_cy).to eq("Welsh markdown")
    end
  end

  describe "#as_form_document_exit_page" do
    let!(:question_page) { create(:page) }
    let!(:exit_page) { create(:exit_page, question_page:) }

    it "returns a hash" do
      expect(exit_page.as_form_document_exit_page).to be_a(Hash)
    end

    it "returns the exit page attributes" do
      expect(exit_page.as_form_document_exit_page).to match a_hash_including("id" => exit_page.id, "heading" => exit_page.heading, "markdown" => exit_page.markdown)
    end
  end
end
