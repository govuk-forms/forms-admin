require "rails_helper"

RSpec.describe "WelshCsvService", feature_multiple_branches: false do
  describe "#as_csv" do
    let(:form) { build :form }

    it "contains the header row" do
      expect(csv_rows(form)[0]).to eq(["Content ID", "English content", "Welsh content"])
    end

    it "contains the form name" do
      expect(csv_rows(form)).to include([
        "Form name",
        form.name,
        form.name_cy,
      ])
    end

    context "when the form has a declaration" do
      let(:form) { build :form, declaration_text: "Declaration text", declaration_text_cy: "Welsh Declaration text" }

      it "contains the declaration" do
        expect(csv_rows(form)).to include([
          "Declaration",
          "Declaration text",
          "Welsh Declaration text",
        ])
      end
    end

    context "when the form has a what happens next" do
      let(:form) { build :form, what_happens_next_markdown: "What happens next text", what_happens_next_markdown_cy: "Welsh What happens next text" }

      it "contains the what happens next" do
        expect(csv_rows(form)).to include([
          "Information about what happens next",
          "What happens next text",
          "Welsh What happens next text",
        ])
      end
    end

    context "when the form has a payment URL" do
      let(:form) { build :form, payment_url: "https://www.gov.uk/payment", payment_url_cy: "https://www.gov.uk/payment_cy" }

      it "contains the payment URL" do
        expect(csv_rows(form)).to include([
          "GOV.UK Pay payment link",
          "https://www.gov.uk/payment",
          "https://www.gov.uk/payment_cy",
        ])
      end
    end

    context "when the form has support information" do
      context "when the form has an email address" do
        let(:form) { build :form, support_email: "support@example.gov.uk", support_email_cy: "support@example.gov.uk" }

        it "contains the support email" do
          expect(csv_rows(form)).to include([
            "Contact details for support - email address",
            "support@example.gov.uk",
            "support@example.gov.uk",
          ])
        end
      end

      context "when the form has a phone number" do
        let(:form) { build :form, support_phone: "English support phone", support_phone_cy: "Welsh support phone" }

        it "contains the support phone" do
          expect(csv_rows(form)).to include([
            "Contact details for support - phone number and opening times",
            "English support phone",
            "Welsh support phone",
          ])
        end
      end

      context "when the form has a URL" do
        let(:form) { build :form, support_url: "https://www.gov.uk/support", support_url_cy: "https://www.gov.uk/support_cy", support_url_text: "Text to describe the contact link", support_url_text_cy: "Welsh Text to describe the contact link" }

        it "contains the support URL" do
          expect(csv_rows(form)).to include([
            "Contact details for support - online contact link",
            "https://www.gov.uk/support",
            "https://www.gov.uk/support_cy",
          ])
        end

        it "contains the support URL text" do
          expect(csv_rows(form)).to include([
            "Contact details for support - online contact link text",
            "Text to describe the contact link",
            "Welsh Text to describe the contact link",
          ])
        end
      end
    end

    context "when the form has questions" do
      let(:form) { build :form, :with_pages }

      it "contains a row for each question" do
        expect(csv_rows(form).length).to eq form.pages.length + 3
      end
    end

    context "and the form has a page" do
      let(:form) { build :form, :with_pages, pages: [page] }
      let(:page) { build :page, question_text: "Question text", question_text_cy: "Welsh question text" }

      it "contains the question text" do
        expect(csv_rows(form)).to include([
          "Question 1 - question text",
          "Question text",
          "Welsh question text",
        ])
      end
    end

    context "and the form has a page with a hint" do
      let(:form) { build :form, :with_pages, pages: [page] }
      let(:page) { build :page, hint_text: "Hint text", hint_text_cy: "Welsh hint text" }

      it "contains the hint text" do
        expect(csv_rows(form)).to include([
          "Question 1 - hint text",
          "Hint text",
          "Welsh hint text",
        ])
      end
    end

    context "and the form has a page with options" do
      let(:form) { build :form, :with_pages, pages: [page] }
      let(:page) do
        build :page,
              question_text: "Question text",
              answer_type: "selection",
              answer_settings: {
                "only_one_option" => "true",
                "selection_options" => [{ name: "Yes", value: "Yes" }, { name: "No", value: "No" }],
              }.to_json,
              answer_settings_cy: {
                "only_one_option" => "true",
                "selection_options" => [{ name: "Ydy", value: "Yes" }, { name: "Nac ydy", value: "No" }],
              }.to_json
      end

      it "contains the options" do
        expect(csv_rows(form)).to include([
          "Question 1 - option 1",
          "Yes",
          "Ydy",
        ], [
          "Question 1 - option 2",
          "No",
          "Nac ydy",
        ])
      end
    end

    context "and the form has a page with guidance" do
      let(:form) { build :form, :with_pages, pages: [page] }
      let(:page) do
        build :page,
              guidance_markdown: "Markdown",
              guidance_markdown_cy: "Welsh markdown",
              page_heading: "Page heading",
              page_heading_cy: "Welsh page heading"
      end

      it "contains the guidance" do
        expect(csv_rows(form)).to include([
          "Question 1 - guidance text",
          "Markdown",
          "Welsh markdown",
        ], [
          "Question 1 - page heading",
          "Page heading",
          "Welsh page heading",
        ])
      end
    end

    context "when the page has a none of the above question" do
      let(:form) { build :form, :with_pages, pages: [page] }
      let(:page) do
        page = build :page,
                     :selection_with_none_of_the_above_question,
                     none_of_the_above_question_text: "None of the above question?"
        page.answer_settings_cy = page.answer_settings.as_json
        page.answer_settings_cy[:none_of_the_above_question][:question_text] = "Welsh None of the above question?"
        page
      end

      it "contains the none of the above question" do
        expect(csv_rows(form)).to include([
          "Question 1 - question or label if 'None of the above' is selected",
          "None of the above question?",
          "Welsh None of the above question?",
        ])
      end
    end

    context "when the page has an exit page" do
      context "when the multiple branches feature is enabled", :feature_multiple_branches do
        let(:form) do
          create(
            :form,
            :with_pages,
            pages: [
              build(
                :page,
                position: 1,
                exit_pages: [
                  build(
                    :exit_page,
                    heading: "Exit page 1 for question 1 heading",
                    markdown: "Exit page 1 for question 1 markdown.",
                    heading_cy: "Welsh exit page 1 for question 1 heading",
                    markdown_cy: "Welsh exit page 1 for question 1 markdown.",
                  ),
                ],
              ),
              build(
                :page,
                position: 2,
                exit_pages: [
                  build(
                    :exit_page,
                    heading: "Exit page 1 for question 2 heading",
                    markdown: "Exit page 1 for question 2 markdown.",
                    heading_cy: "Welsh exit page 1 for question 2 heading",
                    markdown_cy: "Welsh exit page 1 for question 2 markdown.",
                  ),
                  build(
                    :exit_page,
                    heading: "Exit page 2 for question 2 heading",
                    markdown: "Exit page 2 for question 2 markdown.",
                    heading_cy: "Welsh exit page 2 for question 2 heading",
                    markdown_cy: "Welsh exit page 2 for question 2 markdown.",
                  ),
                ],
              ),
            ],
          )
        end

        it "contains the exit page headings" do
          expect(csv_rows(form)).to include(
            [
              "Question 1 - exit page 1 heading",
              "Exit page 1 for question 1 heading",
              "Welsh exit page 1 for question 1 heading",
            ],
            [
              "Question 2 - exit page 1 heading",
              "Exit page 1 for question 2 heading",
              "Welsh exit page 1 for question 2 heading",
            ],
            [
              "Question 2 - exit page 2 heading",
              "Exit page 2 for question 2 heading",
              "Welsh exit page 2 for question 2 heading",
            ],
          )
        end

        it "contains the exit page markdown" do
          expect(csv_rows(form)).to include(
            [
              "Question 1 - exit page 1 content",
              "Exit page 1 for question 1 markdown.",
              "Welsh exit page 1 for question 1 markdown.",
            ],
            [
              "Question 2 - exit page 1 content",
              "Exit page 1 for question 2 markdown.",
              "Welsh exit page 1 for question 2 markdown.",
            ],
            [
              "Question 2 - exit page 2 content",
              "Exit page 2 for question 2 markdown.",
              "Welsh exit page 2 for question 2 markdown.",
            ],
          )
        end
      end

      context "when the multiple branches feature is not enabled", feature_multiple_branches: false do
        let(:form) { build :form, :with_pages, pages: [page] }
        let(:page) { create :page, position: 1, routing_conditions: [condition] }
        let(:condition) { create :condition, :with_exit_page, exit_page_heading: "Exit page heading", exit_page_markdown: "Exit page markdown", exit_page_heading_cy: "Welsh exit page heading", exit_page_markdown_cy: "Welsh exit page markdown" }

        it "contains the exit page heading" do
          expect(csv_rows(form)).to include([
            "Question 1 - exit page heading",
            "Exit page heading",
            "Welsh exit page heading",
          ])
        end
      end
    end

    context "with a complete example" do
      let(:form) do
        build :form,
              :with_pages,
              name: "A form",
              name_cy: "Welsh A form",
              what_happens_next_markdown: "English what happens next",
              what_happens_next_markdown_cy: "Welsh what happens next",
              privacy_policy_url: "https://www.gov.uk/privacy",
              payment_url: "https://www.gov.uk/payment",
              payment_url_cy: "https://www.gov.uk/payment_cy",
              support_email: "support@example.gov.uk",
              support_email_cy: "support@example.gov.uk",
              support_phone: "English support phone",
              support_phone_cy: "Welsh support phone",
              support_url: "https://www.gov.uk/support",
              support_url_cy: "https://www.gov.uk/support_cy",
              support_url_text: "Support URL text",
              support_url_text_cy: "Welsh Support URL text",
              declaration_text: "Declaration text",
              pages: [page, another_page]
      end
      let(:page) do
        page = build :page,
                     :selection_with_none_of_the_above_question,
                     question_text: "None of the above question?",
                     question_text_cy: "Welsh None of the above question?",
                     none_of_the_above_question_text: "None of the above question?",
                     routing_conditions: [condition]
        page.answer_settings_cy = page.answer_settings.as_json
        page.answer_settings_cy[:none_of_the_above_question][:question_text] = "Welsh None of the above question?"
        page
      end
      let(:condition) { create :condition, :with_exit_page, exit_page_heading: "Exit page heading", exit_page_markdown: "Exit page markdown", exit_page_heading_cy: "Welsh exit page heading", exit_page_markdown_cy: "Welsh exit page markdown" }
      let(:another_page) { build :page, question_text: "What?", question_text_cy: "Welsh What?", page_heading: "Page heading", page_heading_cy: "Welsh Page heading", guidance_markdown: "This is the guidance.", guidance_markdown_cy: "Welsh This is the guidance." }

      it "returns a CSV with a header row and the expected rows" do
        csv = csv_rows(form)

        expected_csv = [["Content ID", "English content", "Welsh content"],
                        ["Form name", "A form", "Welsh A form"],
                        ["Question 1 - question text", "None of the above question?", "Welsh None of the above question?"],
                        ["Question 1 - option 1", "Option 1", "Option 1"],
                        ["Question 1 - option 2", "Option 2", "Option 2"],
                        ["Question 1 - question or label if 'None of the above' is selected", "None of the above question?", "Welsh None of the above question?"],
                        ["Question 1 - exit page heading", "Exit page heading", "Welsh exit page heading"],
                        ["Question 1 - exit page content", "Exit page markdown", "Welsh exit page markdown"],
                        ["Question 2 - page heading", "Page heading", "Welsh Page heading"],
                        ["Question 2 - guidance text", "This is the guidance.", "Welsh This is the guidance."],
                        ["Question 2 - question text", "What?", "Welsh What?"],
                        ["Declaration", "Declaration text", ""],
                        ["Information about what happens next", "English what happens next", "Welsh what happens next"],
                        ["GOV.UK Pay payment link", "https://www.gov.uk/payment", "https://www.gov.uk/payment_cy"],
                        ["Link to privacy information for this form", "https://www.gov.uk/privacy", ""],
                        ["Contact details for support - email address", "support@example.gov.uk", "support@example.gov.uk"],
                        ["Contact details for support - phone number and opening times", "English support phone", "Welsh support phone"],
                        ["Contact details for support - online contact link", "https://www.gov.uk/support", "https://www.gov.uk/support_cy"],
                        ["Contact details for support - online contact link text", "Support URL text", "Welsh Support URL text"]]
        expect(csv).to eq(expected_csv)
      end
    end
  end

  describe "#filename" do
    let(:form) { build :form, name: "My form: \"full of odd.\\..\. characters\"" }

    it "returns a filename with a safe form name" do
      expect(WelshCsvService.new(form).filename).to eq("my_form_full_of_odd_characters.csv")
    end

    context "when the form name is too long" do
      let(:form) { build :form, name: "a" * 120 }

      it "returns a filename with a safe form name" do
        expect(WelshCsvService.new(form).filename.length).to eq(80)
      end
    end
  end
end

def csv_rows(form)
  csv = WelshCsvService.new(form).as_csv
  CSV.parse(csv)
end
