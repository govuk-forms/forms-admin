require "rails_helper"

RSpec.describe WelshTranslationContentLabels do
  subject(:helper) { Class.new { include WelshTranslationContentLabels }.new }

  describe "#is_selection_option?" do
    it "returns true for a valid selection option label" do
      expect(helper.is_selection_option?("Question 1 - option 1")).to be true
    end

    it "returns false for a question text label" do
      expect(helper.is_selection_option?("Question 1 - question text")).to be false
    end
  end

  describe "#is_question_text?" do
    it "returns true for a question text label" do
      expect(helper.is_question_text?("Question 1 - question text")).to be true
    end

    it "returns false for a hint text label" do
      expect(helper.is_question_text?("Question 1 - hint text")).to be false
    end
  end

  describe "#is_exit_page_heading?" do
    it "returns true for a condition-style exit page heading label" do
      expect(helper.is_exit_page_heading?("Question 1 - exit page heading")).to be true
    end

    it "returns true for a numbered exit page heading label" do
      expect(helper.is_exit_page_heading?("Question 1 - exit page 2 heading")).to be true
    end

    it "returns false for an exit page content label" do
      expect(helper.is_exit_page_heading?("Question 1 - exit page content")).to be false
    end

    it "returns false for a question text label" do
      expect(helper.is_exit_page_heading?("Question 1 - question text")).to be false
    end
  end

  describe "#question_number_from_label" do
    it "returns the question number from a question text label" do
      expect(helper.question_number_from_label("Question 3 - question text")).to eq(3)
    end

    it "returns the question number from a selection option label" do
      expect(helper.question_number_from_label("Question 12 - option 2")).to eq(12)
    end

    it "returns nil for a label with no question number" do
      expect(helper.question_number_from_label("Form name")).to be_nil
    end
  end
end
