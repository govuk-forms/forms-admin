require "rails_helper"

describe StepSummaryCardPresenter do
  let(:step) { build :form_document_step, is_optional: }
  let(:is_optional) { false }
  let(:steps) do
    [step, *build_list(:form_document_step, 5)]
  end
  let(:presenter) { described_class.call(step:, steps:) }

  describe "#build_card" do
    before do
      allow(StepSummaryCardService).to receive(:call).and_return(OpenStruct.new(all_options_for_answer_type: [1, 2]))
    end

    it "includes a title" do
      expect(presenter.build_card[:title]).to eq "1. #{step.question_text}"
    end

    context "when the step is a selection question" do
      let(:step) { build :form_document_step, :with_selection_settings, is_optional: }

      it "includes a title without (optional) added to it" do
        expect(presenter.build_card[:title]).to eq "1. #{step.question_text}"
      end
    end

    context "when question is optional" do
      let(:is_optional) { "true" }

      it "includes a title with (optional) added to it" do
        expect(presenter.build_card[:title]).to eq "1. #{step.question_text} (optional)"
      end

      context "when the step is a selection question" do
        let(:step) { build :form_document_step, :with_selection_settings, is_optional: }

        it "includes a title without (optional) added to it" do
          expect(presenter.build_card[:title]).to eq "1. #{step.question_text}"
        end
      end
    end

    context "when question is optional is nil" do
      let(:is_optional) { nil }

      it "includes a title" do
        expect(presenter.build_card[:title]).to eq "1. #{step.question_text}"
      end

      context "when the step is a selection question" do
        let(:step) { build :form_document_step, :with_selection_settings, is_optional: }

        it "includes a title without (optional) added to it" do
          expect(presenter.build_card[:title]).to eq "1. #{step.question_text}"
        end
      end
    end

    context "when file upload question contains guidance text" do
      let(:step) { build :form_document_step, :with_guidance, :with_file_upload_answer_type, is_optional: }

      it "includes the guidance text page heading as title" do
        expect(presenter.build_card[:title]).to eq "1. #{step.page_heading}"
      end

      context "when the question is optional" do
        let(:is_optional) { "true" }

        it "includes a title with (optional) added to it" do
          expect(presenter.build_card[:title]).to eq "1. #{step.page_heading} (optional)"
        end
      end
    end
  end

  describe "#build_summary_list" do
    before do
      allow(StepSummaryCardService).to receive(:call).and_return(OpenStruct.new(all_options_for_answer_type: [1, 2]))
    end

    it "includes an array of rows" do
      expect(presenter.build_summary_list[:rows]).to eq [1, 2]
    end
  end

  describe "#build_bilingual_table" do
    before do
      allow(StepSummaryTableService).to receive(:call).and_return(OpenStruct.new(values_with_welsh_content: [3, 4]))
    end

    it "includes a table head with columns for English and Welsh" do
      expect(presenter.build_bilingual_table[:classes]).to include "app-translation-table"
      expect(presenter.build_bilingual_table[:head]).to eq [
        { text: nil, classes: "app-translation-table__empty-header-cell" },
        { text: I18n.t("forms.welsh_translation.new.english_header") },
        { text: I18n.t("forms.welsh_translation.new.welsh_header") },
      ]
    end

    it "includes an array of rows" do
      expect(presenter.build_bilingual_table[:rows]).to eq [3, 4]
    end

    it "configures the table with a header column" do
      expect(presenter.build_bilingual_table[:first_cell_is_header]).to be true
    end
  end

  describe "#build_untranslated_content" do
    before do
      allow(StepSummaryTableService).to receive(:call).and_return(OpenStruct.new(
                                                                    untranslated_content: [{ summary: "answer_type", text: "Some untranslated content" }],
                                                                  ))
    end

    it "includes an array of rows" do
      expect(presenter.build_untranslated_content).to eq [{ summary: "answer_type", text: "Some untranslated content" }]
    end
  end

  describe "#build_route_tables" do
    before do
      allow(StepSummaryTableService).to receive(:call).and_return(OpenStruct.new(
                                                                    route_content:,
                                                                  ))
    end

    context "when the step has no routes" do
      let(:route_content) { [] }

      it "returns nil" do
        expect(presenter.build_route_tables).to be_nil
      end
    end

    context "when the step has a primary route" do
      let(:route_content) do
        [{ answer_value: "Skip",
           answer_value_cy: "Skip",
           check_page: "10. Skip question",
           check_page_cy: "10. Skip question (Welsh)",
           exit_page: false,
           exit_page_heading: nil,
           exit_page_heading_cy: nil,
           exit_page_markdown: nil,
           exit_page_markdown_cy: nil,
           goto_page: "12. Question",
           goto_page_cy: "12. Question (Welsh)",
           routing_page: "10. Skip question",
           routing_page_cy: "10. Skip question (Welsh)",
           secondary_skip: false }]
      end

      it "returns a table for the route with the correct formatting" do
        expect(presenter.build_route_tables.first[:route_table][:caption]).to eq "Question 1’s route"
        expect(presenter.build_route_tables.first[:route_table][:classes]).to eq(%w[app-translation-table])
        expect(presenter.build_route_tables.first[:route_table][:first_cell_is_header]).to be(true)
        expect(presenter.build_route_tables.first[:route_table][:head]).to eq([
          { classes: "app-translation-table__empty-header-cell", text: nil },
          { text: "English content" },
          { text: "Welsh content" },
        ])
      end

      it "returns nil for the exit page content" do
        expect(presenter.build_route_tables.first[:exit_page_table]).to be_nil
      end

      it "returns a table for the route with the correct row data" do
        expect(presenter.build_route_tables.first[:route_table][:rows]).to eq [
          ["If the answer is", "Skip", "Skip"],
          ["Take the person to", "12. Question", "12. Question (Welsh)"],
        ]
      end
    end

    context "when the step has a secondary skip route" do
      let(:route_content) do
        [{ answer_value: nil,
           answer_value_cy: nil,
           check_page: "2. Branch question (start of a route)",
           check_page_cy: "2. Branch question (start of a route) (Welsh)",
           exit_page: false,
           exit_page_heading: nil,
           exit_page_heading_cy: nil,
           exit_page_markdown: nil,
           exit_page_markdown_cy: nil,
           goto_page: "8. Question after a branch route (end of a secondary skip)",
           goto_page_cy: "8. Question after a branch route (end of a secondary skip) (Welsh)",
           routing_page: "4. Question at the end of branch 1 (start of a secondary skip)",
           routing_page_cy: "4. Question at the end of branch 1 (start of a secondary skip) (Welsh)",
           secondary_skip: true }]
      end

      it "returns a table for the route with the correct formatting" do
        expect(presenter.build_route_tables.first[:route_table][:caption]).to eq "Route for any other answer"
        expect(presenter.build_route_tables.first[:route_table][:classes]).to eq(%w[app-translation-table])
        expect(presenter.build_route_tables.first[:route_table][:first_cell_is_header]).to be(true)
        expect(presenter.build_route_tables.first[:route_table][:head]).to eq([
          { classes: "app-translation-table__empty-header-cell", text: nil },
          { text: "English content" },
          { text: "Welsh content" },
        ])
      end

      it "returns a table for the route with the correct row data" do
        expect(presenter.build_route_tables.first[:route_table][:rows]).to eq([
          ["Continue to", "2. Branch question (start of a route)", "2. Branch question (start of a route) (Welsh)"],
          ["Then after", "4. Question at the end of branch 1 (start of a secondary skip)", "4. Question at the end of branch 1 (start of a secondary skip) (Welsh)"],
          ["skip the person to", "8. Question after a branch route (end of a secondary skip)", "8. Question after a branch route (end of a secondary skip) (Welsh)"],
        ])
      end

      it "returns nil for the exit page content" do
        expect(presenter.build_route_tables.first[:exit_page_table]).to be_nil
      end
    end

    context "when the step has a route with an exit page" do
      let(:route_content) do
        [{ answer_value: "Exit",
           answer_value_cy: "Exit",
           check_page: "13. Exit page question",
           check_page_cy: "13. Exit page question (Welsh)",
           exit_page: true,
           exit_page_heading: "Exit page heading",
           exit_page_heading_cy: "Exit page heading (Welsh)",
           exit_page_markdown: "Exit page markdown",
           exit_page_markdown_cy: "Exit page markdown (Welsh)",
           goto_page: "Check your answers",
           goto_page_cy: "Check your answers",
           routing_page: "13. Exit page question",
           routing_page_cy: "13. Exit page question (Welsh)",
           secondary_skip: false }]
      end

      it "returns a table for the route with the correct formatting" do
        expect(presenter.build_route_tables.first[:route_table][:caption]).to eq "Question 1’s route"
        expect(presenter.build_route_tables.first[:route_table][:classes]).to eq(%w[app-translation-table])
        expect(presenter.build_route_tables.first[:route_table][:first_cell_is_header]).to be(true)
        expect(presenter.build_route_tables.first[:route_table][:head]).to eq([
          { classes: "app-translation-table__empty-header-cell", text: nil },
          { text: "English content" },
          { text: "Welsh content" },
        ])
      end

      it "returns a table for the route with the correct row data" do
        expect(presenter.build_route_tables.first[:route_table][:rows]).to eq([
          ["If the answer is", "Exit", "Exit"],
          ["Take the person to", "Check your answers", "Check your answers"],
        ])
      end

      it "returns a table for the exit page content with the correct formatting" do
        expect(presenter.build_route_tables.first[:exit_page_table][:caption]).to eq("Exit page")
        expect(presenter.build_route_tables.first[:exit_page_table][:classes]).to eq(%w[app-translation-table])
        expect(presenter.build_route_tables.first[:exit_page_table][:first_cell_is_header]).to be(true)
        expect(presenter.build_route_tables.first[:exit_page_table][:head]).to eq([
          { classes: "app-translation-table__empty-header-cell", text: nil },
          { text: "English content" },
          { text: "Welsh content" },
        ])
      end

      it "returns a table for the exit page content with the correct row data" do
        expect(presenter.build_route_tables.first[:exit_page_table][:rows]).to eq([
          ["Page title", "Exit page heading", "Exit page heading (Welsh)"],
          ["Page content", { classes: %w[app-translation-table__markdown-preview], text: "Exit page markdown" }, { classes: %w[app-translation-table__markdown-preview], text: "Exit page markdown (Welsh)" }],
        ])
      end
    end
  end
end
