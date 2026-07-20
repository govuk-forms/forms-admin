require "rails_helper"

describe Reports::AddAnotherAnswerUsageService do
  subject(:features_report_service) { described_class.new }

  describe "#add_another_answer_forms" do
    let!(:add_another_answer_draft_form) { create(:form, state: "draft", pages: draft_form_pages) }
    let(:draft_form_pages) do
      [
        build(:page, answer_type: "name", is_repeatable: true),
      ]
    end
    let!(:add_another_answer_live_form) { create(:form, state: "live", pages: live_form_pages) }
    let(:live_form_pages) do
      [
        (build :page, answer_type: "name", is_repeatable: true),
        (build :page, answer_type: "text", is_repeatable: true),
      ]
    end

    it "obtains all forms in the add another answer report" do
      report = features_report_service.add_another_answer_forms

      expect(report[:forms]).to contain_exactly(
        OpenStruct.new(
          form_id: add_another_answer_draft_form.id,
          name: add_another_answer_draft_form.name,
          state: add_another_answer_draft_form.state,
          repeatable_pages: [OpenStruct.new(page_id: draft_form_pages.first.id, question_text: draft_form_pages.first.question_text)],
        ),
        OpenStruct.new(
          form_id: add_another_answer_live_form.id,
          name: add_another_answer_live_form.name,
          state: add_another_answer_live_form.state,
          repeatable_pages: [
            OpenStruct.new(page_id: live_form_pages.first.id, question_text: live_form_pages.first.question_text),
            OpenStruct.new(page_id: live_form_pages.second.id, question_text: live_form_pages.second.question_text),
          ],
        ),
      )
    end

    it "returns the count" do
      report = features_report_service.add_another_answer_forms
      expect(report[:count]).to eq 2
    end
  end
end
