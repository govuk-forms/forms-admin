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

  describe "#position" do
    let!(:question_page) { create(:page) }
    let!(:exit_page) { create(:exit_page, question_page:) }

    it "returns the position of the exit page" do
      expect(exit_page.position).to eq(1)
    end

    context "when there are multiple exit pages" do
      let!(:second_exit_page) { create(:exit_page, question_page:) }

      it "returns the position of the exit page" do
        expect(second_exit_page.position).to eq(2)
      end
    end
  end

  describe ".positions_for_page" do
    let!(:question_page) { create(:page) }
    let!(:first_exit_page) { create(:exit_page, question_page:, created_at: Time.zone.local(2024, 1, 1, 9, 0, 0)) }
    let!(:second_exit_page) { create(:exit_page, question_page:, created_at: Time.zone.local(2024, 1, 1, 9, 5, 0)) }
    let!(:zeroth_exit_page) { create(:exit_page, question_page:, created_at: Time.zone.local(2024, 1, 1, 8, 0, 0)) }

    it "returns the exit page positions in created_at order" do
      expect(described_class.positions_for_page(question_page)).to include(
        zeroth_exit_page.id => 1,
        first_exit_page.id => 2,
        second_exit_page.id => 3,
      )
    end
  end

  describe "#options_to_this_exit_page" do
    it "when the exit_page has linked conditions, returns an array of the answer values of conditions that go to this exit page" do
      question_page = create(:page)
      exit_page = create(:exit_page, question_page:)
      create(:condition, routing_page: question_page, exit_page_id: exit_page.id, answer_value: "option 1")
      create(:condition, exit_page:, answer_value: "option 2")
      create(:condition, exit_page:, answer_value: "option 3")

      expect(exit_page.options_to_this_exit_page).to eq(["option 1", "option 2", "option 3"])
    end

    it "when the exit_page has no linked conditions, returns an empty array" do
      question_page = create(:page)
      exit_page = create(:exit_page, question_page:)

      expect(exit_page.options_to_this_exit_page).to eq([])
    end
  end
end
