require "rails_helper"

RSpec.describe WelshCsvImportService do
  describe "#import" do
    subject(:import_values) { described_class.new(csv_data).read }

    context "with a valid CSV containing all form-level fields" do
      let(:csv_data) do
        CSV.generate do |csv|
          csv << ["Identifier (do not change)", "Content", "English content", "Welsh content"]
          csv << ["name", "Form name", "My Form", "Fy Ffurflen"]
          csv << ["declaration_markdown", "Declaration", "Declaration text", "Welsh declaration"]
          csv << ["what_happens_next_markdown", "What happens next", "Next steps", "Welsh next steps"]
          csv << ["payment_url", "Payment link", "https://pay.gov.uk/en", "https://pay.gov.uk/cy"]
          csv << ["privacy_policy_url", "Privacy policy", "https://privacy.gov.uk", "https://privacy.gov.uk/cy"]
          csv << ["support_email", "Support email", "help@example.gov.uk", "help@example.gov.uk"]
          csv << ["support_phone", "Support phone", "0800 123 456", "0800 123 456 cy"]
          csv << ["support_url", "Support URL", "https://contact.gov.uk", "https://contact.gov.uk/cy"]
          csv << ["support_url_text", "Support URL text", "Contact us", "Cysylltu â ni"]
        end
      end

      it "maps name" do
        expect(import_values["name"]).to eq("Fy Ffurflen")
      end

      it "maps declaration_markdown" do
        expect(import_values["declaration_markdown"]).to eq("Welsh declaration")
      end

      it "maps what_happens_next_markdown" do
        expect(import_values["what_happens_next_markdown"]).to eq("Welsh next steps")
      end

      it "maps all form-level IDs" do
        expect(import_values.keys).to include(
          "name",
          "declaration_markdown",
          "what_happens_next_markdown",
          "payment_url",
          "privacy_policy_url",
          "support_email",
          "support_phone",
          "support_url",
          "support_url_text",
        )
      end
    end

    context "with a valid CSV containing page-level fields" do
      let(:page_id) { 42 }
      let(:condition_id) { 99 }
      let(:csv_data) do
        CSV.generate do |csv|
          csv << ["Identifier (do not change)", "Content", "English content", "Welsh content"]
          csv << ["page_#{page_id}_question_text", "Question 1 - question text", "What is your name?", "Beth yw eich enw?"]
          csv << ["page_#{page_id}_hint_text", "Question 1 - hint text", "Enter your full name", "Rhowch eich enw llawn"]
          csv << ["page_#{page_id}_page_heading", "Question 1 - page heading", "Page heading", "Pennawd tudalen"]
          csv << ["page_#{page_id}_guidance_markdown", "Question 1 - guidance text", "Some guidance", "Rhywfaint o arweiniad"]
          csv << ["page_#{page_id}_option_0", "Question 1 - option 1", "Yes", "Ydy"]
          csv << ["page_#{page_id}_option_1", "Question 1 - option 2", "No", "Nac ydy"]
          csv << ["page_#{page_id}_none_of_the_above_question", "NoneOfAbove", "None of the above?", "Dim un o'r uchod?"]
          csv << ["condition_#{condition_id}_exit_page_heading", "Exit heading", "You cannot continue", "Ni allwch barhau"]
          csv << ["condition_#{condition_id}_exit_page_markdown", "Exit content", "Sorry", "Mae'n ddrwg"]
        end
      end

      it "maps page question text" do
        expect(import_values["page_#{page_id}_question_text"]).to eq("Beth yw eich enw?")
      end

      it "maps page hint text" do
        expect(import_values["page_#{page_id}_hint_text"]).to eq("Rhowch eich enw llawn")
      end

      it "maps selection option by index" do
        expect(import_values["page_#{page_id}_option_0"]).to eq("Ydy")
        expect(import_values["page_#{page_id}_option_1"]).to eq("Nac ydy")
      end

      it "maps condition exit page fields" do
        expect(import_values["condition_#{condition_id}_exit_page_heading"]).to eq("Ni allwch barhau")
        expect(import_values["condition_#{condition_id}_exit_page_markdown"]).to eq("Mae'n ddrwg")
      end
    end

    context "with empty Welsh content" do
      let(:csv_data) do
        CSV.generate do |csv|
          csv << ["Identifier (do not change)", "Content", "English content", "Welsh content"]
          csv << ["form_name", "Form name", "My Form", ""]
        end
      end

      it "returns an empty string for the Welsh value" do
        expect(import_values["form_name"]).to eq("")
      end
    end

    context "with rows missing an identifier" do
      let(:csv_data) do
        CSV.generate do |csv|
          csv << ["Identifier (do not change)", "Content", "English content", "Welsh content"]
          csv << [nil, "Some label", "English value", "Welsh value"]
          csv << ["name", "Form name", "My Form", "Fy Ffurflen"]
        end
      end

      it "skips rows without an identifier" do
        expect(import_values.keys).not_to include(nil)
        expect(import_values["name"]).to eq("Fy Ffurflen")
      end
    end

    context "when the CSV does not have the identifier column header" do
      let(:csv_data) do
        CSV.generate do |csv|
          csv << ["", "English content", "Welsh content"]
          csv << ["Form name", "My Form", "Fy Ffurflen"]
        end
      end

      it "raises an error" do
        expect { import_values }.to raise_error(WelshCsvImportService::InvalidHeadersError)
      end
    end

    context "when the CSV does not have the Welsh Content column header" do
      let(:csv_data) do
        CSV.generate do |csv|
          csv << [WelshCsvImportService::ID_COLUMN, "English content", ""]
          csv << ["Form name", "My Form", "Fy Ffurflen"]
        end
      end

      it "raises an error" do
        expect { import_values }.to raise_error(WelshCsvImportService::InvalidHeadersError)
      end
    end
  end
end
