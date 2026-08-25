require "rails_helper"

RSpec.describe WelshCsvImportService do
  subject(:service) { described_class.new(file, form) }

  let(:form) do
    create :form,
           :with_pages,
           name: "A form",
           what_happens_next_markdown: "English what happens next",
           privacy_policy_url: "https://www.gov.uk/privacy",
           payment_url: "https://www.gov.uk/payment",
           support_email: "support@example.gov.uk",
           support_phone: "English support phone",
           support_url: "https://www.gov.uk/support",
           support_url_text: "Support URL text",
           declaration_text: "Declaration text",
           pages: [page, another_page]
  end
  let(:page) do
    create :page,
           :selection_with_none_of_the_above_question,
           question_text: "None of the above question?",
           none_of_the_above_question_text: "None of the above question?",
           routing_conditions: [condition]
  end
  let(:condition) { create :condition, :with_exit_page, exit_page_heading: "Exit page heading" }
  let(:another_page) { create :page, question_text: "What?", page_heading: "Page heading", guidance_markdown: "This is the guidance." }

  let(:file) { Tempfile.new }

  after do
    file.unlink
  end

  context "when the CSV is valid" do
    context "when the rows in the CSV match the current form" do
      before do
        rows = [
          ["Content ID", "English content", "Welsh content"],
          ["Form name", "A form", "Welsh A form ôÂŵéï"],
          ["Question 1 - question text", "None of the above question?", "Welsh None of the above question?"],
          ["Question 1 - option 1", "Option 1", "Welsh Option 1"],
          ["Question 1 - option 2", "Option 2", "Welsh Option 2"],
          ["Question 1 - question or label if 'None of the above' is selected", "None of the above question?", "Welsh None of the above question?"],
          ["Question 1 - exit page heading", "Exit page heading", "Welsh exit page heading"],
          ["Question 1 - exit page content", "Exit page markdown", "Welsh exit page markdown"],
          ["Question 2 - page heading", "Page heading", "Welsh Page heading"],
          ["Question 2 - guidance text", "This is the guidance.", "Welsh This is the guidance."],
          ["Question 2 - question text", "What?", "Welsh What?"],
          ["Declaration", "Declaration text", "Welsh declaration text"],
          ["Information about what happens next", "English what happens next", "Welsh what happens next"],
          ["GOV.UK Pay payment link", "https://www.gov.uk/payment", "https://www.gov.uk/payment_cy"],
          ["Link to privacy information for this form", "https://www.gov.uk/privacy", "https://www.gov.uk/privacy_cy"],
          ["Contact details for support - email address", "support@example.gov.uk", "support@example.gov.uk"],
          ["Contact details for support - phone number and opening times", "English support phone", "Welsh support phone"],
          ["Contact details for support - online contact link", "https://www.gov.uk/support", "https://www.gov.uk/support_cy"],
          ["Contact details for support - online contact link text", "Support URL text", "Welsh Support URL text"],
        ]
        file.write(rows.map(&:to_csv).join)
        file.rewind
      end

      it "returns the translations data" do
        expect(service.read).to eq({
          "Form name" => "Welsh A form ôÂŵéï",
          "Question 1 - question text" => "Welsh None of the above question?",
          "Question 1 - option 1" => "Welsh Option 1",
          "Question 1 - option 2" => "Welsh Option 2",
          "Question 1 - question or label if 'None of the above' is selected" => "Welsh None of the above question?",
          "Question 1 - exit page heading" => "Welsh exit page heading",
          "Question 1 - exit page content" => "Welsh exit page markdown",
          "Question 2 - page heading" => "Welsh Page heading",
          "Question 2 - guidance text" => "Welsh This is the guidance.",
          "Question 2 - question text" => "Welsh What?",
          "Declaration" => "Welsh declaration text",
          "Information about what happens next" => "Welsh what happens next",
          "GOV.UK Pay payment link" => "https://www.gov.uk/payment_cy",
          "Link to privacy information for this form" => "https://www.gov.uk/privacy_cy",
          "Contact details for support - email address" => "support@example.gov.uk",
          "Contact details for support - phone number and opening times" => "Welsh support phone",
          "Contact details for support - online contact link" => "https://www.gov.uk/support_cy",
          "Contact details for support - online contact link text" => "Welsh Support URL text",
        })
      end
    end
  end

  context "when the CSV has invalid headers" do
    before do
      rows = [
        ["Content ID", "Unexpected", "Welsh content"],
        ["Form name", "A form", "Welsh A form"],
      ]
      file.write(rows.map(&:to_csv).join)
      file.rewind
    end

    it "raises an InvalidHeadersError" do
      expect { service.read }.to raise_error(WelshCsvImportService::InvalidHeadersError)
    end
  end

  context "when the headers are in the wrong order" do
    before do
      rows = [
        ["Welsh content", "English content", "Content ID"],
        ["Form name", "Welsh A form", "A form"],
      ]
      file.write(rows.map(&:to_csv).join)
      file.rewind
    end

    it "raises an InvalidHeadersError" do
      expect { service.read }.to raise_error(WelshCsvImportService::InvalidHeadersError)
    end
  end
end
