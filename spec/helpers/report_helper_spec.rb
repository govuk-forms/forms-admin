require "rails_helper"

RSpec.describe ReportHelper, type: :helper do
  let(:forms) do
    [
      { "form_id" => 1, "tag" => "live", "content" => { "name" => "All question types form" }, "organisation_name" => "Government Digital Service" },
      { "form_id" => 3, "tag" => "live", "content" => { "name" => "Branch route form" }, "organisation_name" => "Ministry of Tests" },
      { "form_id" => 4, "tag" => "live", "content" => { "name" => "Skip route form" }, "organisation_name" => "Department for Testing" },
    ]
  end

  let(:forms_with_routes) do
    [
      { "form_id" => 3, "tag" => "live", "content" => { "name" => "Branch route form" }, "organisation_name" => "Ministry of Tests", "metadata" => { "number_of_questions_with_routes" => 2 } },
      { "form_id" => 4, "tag" => "live", "content" => { "name" => "Skip route form" }, "organisation_name" => "Department for Testing", "metadata" => { "number_of_questions_with_routes" => 1 } },
    ]
  end

  let(:questions) do
    [
      { "type" => "question", "data" => { "question_text" => "Email address" }, "form" => { "form_id" => 1, "tag" => "live", "content" => { "name" => "All question types form" }, "organisation_name" => "Government Digital Service" } },
      { "type" => "question", "data" => { "question_text" => "What’s your email address?" }, "form" => { "form_id" => 3, "tag" => "live", "content" => { "name" => "Branch route form" }, "organisation_name" => "Ministry of Tests" } },
    ]
  end

  describe "#report_table" do
    before do
      allow(helper).to receive(:report_forms_table).and_call_original
      allow(helper).to receive(:report_forms_with_routes_table).and_call_original
      allow(helper).to receive(:report_questions_table).and_call_original
    end

    context "with 'forms' type" do
      it "calls #report_forms_table" do
        helper.report_table(:forms, forms)
        expect(helper).to have_received(:report_forms_table).with(forms)
      end
    end

    context "with 'forms_with_routes' type" do
      it "calls #report_forms_with_routes_table" do
        helper.report_table(:forms_with_routes, forms_with_routes)
        expect(helper).to have_received(:report_forms_with_routes_table).with(forms_with_routes)
      end
    end

    context "with 'questions' type" do
      it "calls #report_questions_table" do
        helper.report_table(:questions, questions)
        expect(helper).to have_received(:report_questions_table).with(questions)
      end
    end

    context "with 'selection_questions' type" do
      subject(:table) { helper.report_table(:selection_questions, questions) }

      let(:questions) do
        pages = [
          build(:page, :selection_with_radios, question_text: "Radios question", is_optional: true),
          build(:page, :selection_with_checkboxes, question_text: "Checkboxes question", is_optional: false),
        ]

        [
          question_data_from_page(pages[0], forms[0]),
          question_data_from_page(pages[1], forms[1]),
        ]
      end

      it "includes the correct table head" do
        expect(table[:head]).to eq [
          I18n.t("reports.form_or_questions_list_table.headings.form_name"),
          I18n.t("reports.form_or_questions_list_table.headings.organisation"),
          I18n.t("reports.form_or_questions_list_table.headings.question_text"),
          I18n.t("reports.form_or_questions_list_table.headings.number_of_options"),
          I18n.t("reports.form_or_questions_list_table.headings.none_of_the_above"),
        ]
      end

      it "formats a link for each form for the first column of each row" do
        expect(table[:rows].map(&:first)).to eq [
          "<a class=\"govuk-link\" href=\"/forms/1/live/pages\">All question types form</a>",
          "<a class=\"govuk-link\" href=\"/forms/3/live/pages\">Branch route form</a>",
        ]
      end

      it "includes the organisation name for each form for the second column of each row" do
        expect(table[:rows].map(&:second)).to eq [
          "Government Digital Service",
          "Ministry of Tests",
        ]
      end

      it "includes the question text for each question for the third column of each row" do
        expect(table[:rows].map(&:third)).to eq [
          "Radios question",
          "Checkboxes question",
        ]
      end

      it "includes the number of options for each question for the fourth column of each row" do
        expect(table[:rows].map(&:fourth)).to eq %w[30 2]
      end

      it "includes whether 'none of the above' is included for each question for the fifth column of each row" do
        expect(table[:rows].map(&:fifth)).to eq [
          I18n.t("reports.form_or_questions_list_table.values.yes"),
          I18n.t("reports.form_or_questions_list_table.values.no"),
        ]
      end
    end

    context "with 'selection_questions_with_none_of_the_above' type" do
      subject(:table) { helper.report_table(:selection_questions_with_none_of_the_above, questions) }

      let(:questions) do
        pages = [
          build(:page, :selection_with_none_of_the_above_question,
                question_text: "With optional follow-up",
                none_of_the_above_question_text: "You can enter something",
                none_of_the_above_question_is_optional: "true"),
          build(:page, :selection_with_none_of_the_above_question,
                question_text: "With mandatory follow-up",
                none_of_the_above_question_text: "You must enter something",
                none_of_the_above_question_is_optional: "false"),
          build(:page, :with_selection_settings, question_text: "Without follow-up", is_optional: true),
        ]

        [
          question_data_from_page(pages[0], forms[0]),
          question_data_from_page(pages[1], forms[1]),
          question_data_from_page(pages[2], forms[2]),
        ]
      end

      it "includes the correct table head" do
        expect(table[:head]).to eq [
          I18n.t("reports.form_or_questions_list_table.headings.form_name"),
          I18n.t("reports.form_or_questions_list_table.headings.organisation"),
          I18n.t("reports.form_or_questions_list_table.headings.question_text"),
          I18n.t("reports.form_or_questions_list_table.headings.none_of_the_above_follow_up_question"),
        ]
      end

      it "formats a link for each form for the first column of each row" do
        expect(table[:rows].map(&:first)).to eq [
          "<a class=\"govuk-link\" href=\"/forms/1/live/pages\">All question types form</a>",
          "<a class=\"govuk-link\" href=\"/forms/3/live/pages\">Branch route form</a>",
          "<a class=\"govuk-link\" href=\"/forms/4/live/pages\">Skip route form</a>",
        ]
      end

      it "includes the organisation name for each form for the second column of each row" do
        expect(table[:rows].map(&:second)).to eq [
          "Government Digital Service",
          "Ministry of Tests",
          "Department for Testing",
        ]
      end

      it "includes the question text for each question for the third column of each row" do
        expect(table[:rows].map(&:third)).to eq [
          "With optional follow-up",
          "With mandatory follow-up",
          "Without follow-up",
        ]
      end

      it "includes the none of the above follow-up question for each question for the fourth column of each row" do
        expect(table[:rows].map(&:fourth)).to eq [
          "You can enter something (optional)",
          "You must enter something",
          "No follow-up question",
        ]
      end
    end
  end

  describe "#report_forms_table" do
    it "has table head" do
      expect(helper.report_forms_table(forms)).to include(
        head: helper.report_forms_table_head,
      )
    end

    it "has table rows" do
      expect(helper.report_forms_table(forms)).to include(
        rows: helper.report_forms_table_rows(forms),
      )
    end
  end

  describe "#report_forms_with_routes_table" do
    it "has table head" do
      expect(helper.report_forms_with_routes_table(forms_with_routes)).to include(
        head: helper.report_forms_with_routes_table_head,
      )
    end

    it "has table rows" do
      expect(helper.report_forms_with_routes_table(forms_with_routes)).to include(
        rows: helper.report_forms_with_routes_table_rows(forms_with_routes),
      )
    end
  end

  describe "#report_questions_table" do
    it "has table head" do
      expect(helper.report_questions_table(questions)).to include(
        head: helper.report_questions_table_head,
      )
    end

    it "has table rows" do
      expect(helper.report_questions_table(questions)).to include(
        rows: helper.report_questions_table_rows(questions),
      )
    end
  end

  describe "#report_forms_table_head" do
    it "returns the column headings for a table of forms" do
      expect(helper.report_forms_table_head).to eq [
        "Form name",
        "Organisation",
      ]
    end
  end

  describe "#report_forms_table_rows" do
    it "returns an array of arrays of strings" do
      expect(helper.report_forms_table_rows(forms))
        .to be_an(Array)
              .and(all(be_an(Array)))
              .and(all(all(be_a(String))))
    end

    it "returns a row for each form" do
      expect(helper.report_forms_table_rows(forms).length)
        .to eq forms.length
    end

    it "has a column in each row for each column heading" do
      expect(helper.report_forms_table_rows(forms).map(&:length))
        .to all eq helper.report_forms_table_head.length
    end

    it "formats a link for each form for the first column of each row" do
      expect(helper.report_forms_table_rows(forms).map(&:first)).to eq [
        "<a class=\"govuk-link\" href=\"/forms/1/live/pages\">All question types form</a>",
        "<a class=\"govuk-link\" href=\"/forms/3/live/pages\">Branch route form</a>",
        "<a class=\"govuk-link\" href=\"/forms/4/live/pages\">Skip route form</a>",
      ]
    end

    context "when the form is live" do
      it "formats a link to the live form pages" do
        form = forms.first.merge("tag" => "live")
        expect(helper.report_forms_table_rows([form]).first.first).to eq(
          "<a class=\"govuk-link\" href=\"/forms/1/live/pages\">All question types form</a>",
        )
      end
    end

    context "when the form is a draft" do
      it "formats a link to the form pages" do
        form = forms.first.merge("tag" => "draft")
        expect(helper.report_forms_table_rows([form]).first.first).to eq(
          "<a class=\"govuk-link\" href=\"/forms/1/pages\">All question types form</a>",
        )
      end
    end

    it "includes the organisation name for each form for the second column of each row" do
      expect(helper.report_forms_table_rows(forms).map(&:second)).to eq [
        "Government Digital Service",
        "Ministry of Tests",
        "Department for Testing",
      ]
    end
  end

  describe "#report_forms_with_routes_table_head" do
    it "returns the column headings for a table of forms and details of their routes" do
      expect(helper.report_forms_with_routes_table_head).to eq [
        "Form name",
        "Organisation",
        "Number of questions with routes",
      ]
    end
  end

  describe "#report_forms_with_routes_table_rows" do
    let(:forms) { forms_with_routes }

    it "returns an array of arrays of strings" do
      expect(helper.report_forms_with_routes_table_rows(forms))
        .to be_an(Array)
              .and(all(be_an(Array)))
              .and(all(all(be_a(String))))
    end

    it "returns a row for each form" do
      expect(helper.report_forms_with_routes_table_rows(forms).length)
        .to eq forms.length
    end

    it "has a column in each row for each column heading" do
      expect(helper.report_forms_with_routes_table_rows(forms).map(&:length))
        .to all eq helper.report_forms_with_routes_table_head.length
    end

    it "formats a link for each form for the first column of each row" do
      expect(helper.report_forms_with_routes_table_rows(forms).map(&:first)).to eq [
        "<a class=\"govuk-link\" href=\"/forms/3/live/pages\">Branch route form</a>",
        "<a class=\"govuk-link\" href=\"/forms/4/live/pages\">Skip route form</a>",
      ]
    end

    it "includes the organisation name for each form for the second column of each row" do
      expect(helper.report_forms_with_routes_table_rows(forms).map(&:second)).to eq [
        "Ministry of Tests",
        "Department for Testing",
      ]
    end

    it "includes the number of questions with routes in the form" do
      expect(helper.report_forms_with_routes_table_rows(forms).map(&:third)).to eq %w[
        2
        1
      ]
    end
  end

  describe "#report_questions_table_head" do
    it "returns the column headings for a table of questions" do
      expect(helper.report_questions_table_head).to eq [
        "Form name",
        "Organisation",
        "Question text",
      ]
    end
  end

  describe "#report_questions_table_rows" do
    it "returns an array of arrays of strings" do
      expect(helper.report_questions_table_rows(questions))
        .to be_an(Array)
              .and(all(be_an(Array)))
              .and(all(all(be_a(String))))
    end

    it "formats a link for each form for the first column of each row" do
      expect(helper.report_questions_table_rows(questions).map(&:first)).to eq [
        "<a class=\"govuk-link\" href=\"/forms/1/live/pages\">All question types form</a>",
        "<a class=\"govuk-link\" href=\"/forms/3/live/pages\">Branch route form</a>",
      ]
    end

    it "includes the organisation name for each form for the second column of each row" do
      expect(helper.report_questions_table_rows(questions).map(&:second)).to eq [
        "Government Digital Service",
        "Ministry of Tests",
      ]
    end

    it "includes the question text for each question for the third column of each row" do
      expect(helper.report_questions_table_rows(questions).map(&:third)).to eq [
        "Email address",
        "What’s your email address?",
      ]
    end
  end

  def question_data_from_page(page, form_data)
    page.as_form_document_step(nil).as_json.merge("form" => form_data)
  end
end
