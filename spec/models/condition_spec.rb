require "rails_helper"

RSpec.describe Condition, type: :model do
  subject(:condition) { described_class.new }

  describe "factory" do
    it "has a valid factory" do
      condition = create :condition
      expect(condition).to be_valid
    end
  end

  describe "destroying" do
    subject!(:condition) do
      create :condition
    end

    it "deletes the condition" do
      expect {
        condition.destroy
      }.to change(described_class, :count).by(-1)

      expect(condition).to be_destroyed
    end

    context "when there is another condition that depends on this one" do
      subject!(:condition) do
        described_class.create! check_page: start_of_branches, routing_page: start_of_branches, goto_page: start_of_second_branch
      end

      let!(:secondary_skip_condition) do
        described_class.create! check_page: start_of_branches, routing_page: end_of_first_branch, goto_page_id: end_of_branches
      end

      let(:start_of_branches) { create :page }
      let(:end_of_first_branch) { create :page }
      let(:start_of_second_branch) { create :page }
      let(:end_of_branches) { create :page }

      it "destroys the other condition" do
        condition.reload

        expect {
          condition.destroy!
        }.to change(described_class, :count).by(-2)

        expect(described_class).not_to exist(secondary_skip_condition.id)
      end
    end
  end

  it_behaves_like "implements condition methods"

  describe "validations" do
    it "validates" do
      page = create :page
      condition.routing_page_id = page.id
      expect(condition).to be_valid
    end

    it "requires routing_page_id" do
      expect(condition).to be_invalid
      expect(condition.errors[:routing_page]).to include("must exist")
    end
  end

  describe "translations" do
    let(:condition) { create(:condition) }

    it "can set and read translated attributes for :en and :cy locales" do
      Mobility.with_locale(:en) do
        condition.exit_page_heading = "english_exit_page_heading"
        condition.exit_page_markdown = "english_exit_page_markdown"
        condition.save!
      end

      Mobility.with_locale(:cy) do
        condition.exit_page_heading = "welsh_exit_page_heading"
        condition.exit_page_markdown = "welsh_exit_page_markdown"
        condition.save!
      end

      Mobility.with_locale(:en) do
        condition.reload
        expect(condition.exit_page_heading).to eq("english_exit_page_heading")
        expect(condition.exit_page_markdown).to eq("english_exit_page_markdown")
      end

      Mobility.with_locale(:cy) do
        condition.reload
        expect(condition.exit_page_heading).to eq("welsh_exit_page_heading")
        expect(condition.exit_page_markdown).to eq("welsh_exit_page_markdown")
      end
    end
  end

  describe ".create_and_update_form!" do
    let(:form) { create(:form) }
    let(:routing_page) { create(:page, form:) }
    let(:goto_page) { create(:page, form:) }
    let(:condition_params) do
      { check_page_id: routing_page.id,
        routing_page_id: routing_page.id,
        answer_value: "Yes",
        goto_page_id: goto_page.id,
        skip_to_end: false,
        exit_page_heading: nil,
        exit_page_markdown: nil }
    end

    it "saves the condition to the database" do
      expect {
        described_class.create_and_update_form!(**condition_params)
      }.to change(described_class, :count).by(1)
    end

    it "creates the condition with the given attributes" do
      created_condition = described_class.create_and_update_form!(**condition_params)
      expect(created_condition).to have_attributes(
        check_page_id: routing_page.id,
        routing_page_id: routing_page.id,
        goto_page_id: goto_page.id,
        answer_value: "Yes",
        skip_to_end: false,
      )
    end

    it "returns a condition record" do
      expect(described_class.create_and_update_form!(**condition_params)).to be_a(described_class)
    end

    context "when the form question section is complete" do
      let(:form) { create(:form, question_section_completed: true) }

      it "updates the form to mark the question section as incomplete" do
        expect {
          described_class.create_and_update_form!(**condition_params)
        }.to change { Form.find(form.id).question_section_completed }.to(false)
      end
    end
  end

  describe "#save_and_update_form" do
    subject(:condition) { create :condition, :with_exit_page, routing_page: page, check_page: page }

    let(:page) { create :page, :with_selection_settings, form: }
    let(:form) { create :form, question_section_completed: true }

    before do
      condition.exit_page_heading = "New heading"
      condition.save_and_update_form
    end

    it "updates the condition" do
      expect(condition.reload.exit_page_heading).to eq("New heading")
    end

    it "sets form.question_section_completed to false" do
      expect(form.reload.question_section_completed).to be false
    end

    context "when the form is live" do
      let(:form) { create :form, :live }

      it "updates the form state to live_with_draft" do
        expect(form.reload.state).to eq("live_with_draft")
      end
    end
  end

  describe "#destroy_and_update_form!" do
    subject(:condition) { create :condition, :with_exit_page, routing_page: page, check_page: page }

    let(:page) { create :page, :with_selection_settings, form: }
    let(:form) { create :form, question_section_completed: true }

    before do
      condition.destroy_and_update_form!
    end

    it "destroys the condition" do
      expect(condition).to be_destroyed
    end

    it "sets form.question_section_completed to false" do
      expect(form.reload.question_section_completed).to be false
    end

    context "when the form is live" do
      let(:form) { create :form, :live }

      it "updates the form state to live_with_draft" do
        expect(form.reload.state).to eq("live_with_draft")
      end
    end
  end

  describe "#validation_errors" do
    let(:form) { create :form }
    let(:routing_page) { create :page, form: }
    let(:goto_page) { nil }
    let(:condition) { create :condition, routing_page_id: routing_page.id, goto_page_id: nil }

    it "returns array of validation error objects" do
      expect(condition.validation_errors).to eq([DataStruct.new(name: "goto_page_doesnt_exist")])
    end

    it "calls each validation method" do
      %i[warning_goto_page_doesnt_exist
         warning_answer_doesnt_exist
         warning_routing_to_next_page
         warning_goto_page_before_routing_page ].each do |validation_methods|
        expect(condition).to receive(validation_methods)
      end
      condition.validation_errors
    end

    it "calls warning_goto_page_doesnt_exist" do
      expect(condition).to receive(:warning_goto_page_doesnt_exist)
      condition.validation_errors
    end

    context "when no validation errors" do
      let(:goto_page) { create :page, form: }
      let(:condition) { create :condition, routing_page_id: routing_page.id, goto_page_id: goto_page.id }

      it "returns empty array if there are no validation errors" do
        expect(condition.validation_errors).to be_empty
      end
    end
  end

  describe "#warning_goto_page_doesnt_exist" do
    let(:form) { create :form }
    let(:routing_page) { create :page, form: }
    let(:goto_page) { create :page, form: }
    let(:condition) { create :condition, routing_page_id: routing_page.id, goto_page_id: goto_page.id }

    it "returns nil if goto page exists" do
      expect(condition.warning_goto_page_doesnt_exist).to be_nil
    end

    context "when goto page is null and skip_to_end is true" do
      let(:condition) { create :condition, routing_page_id: routing_page.id, goto_page_id: nil, skip_to_end: true }

      it "returns nil" do
        expect(condition.warning_goto_page_doesnt_exist).to be_nil
      end
    end

    context "when goto page has been deleted" do
      let(:condition) { create :condition, routing_page_id: routing_page.id, goto_page_id: 999 }

      it "returns object with error short name code" do
        expect(condition.warning_goto_page_doesnt_exist).to eq(DataStruct.new(name: "goto_page_doesnt_exist"))
      end
    end

    context "when goto page may belong to another form" do
      let(:goto_page) { create :page }

      it "returns object with error short name code" do
        expect(condition.warning_goto_page_doesnt_exist).to eq(DataStruct.new(name: "goto_page_doesnt_exist"))
      end
    end

    context "when is_exit_page? using exit_page_markdown" do
      let(:condition) { create :condition, routing_page_id: routing_page.id, goto_page_id: nil, exit_page_markdown: "exit page" }

      it "returns nil" do
        expect(condition.warning_goto_page_doesnt_exist).to be_nil
      end
    end

    context "when exit_page_id is present using ExitPage" do
      let(:exit_page) { create :exit_page }
      let(:condition) { create :condition, routing_page_id: routing_page.id, goto_page_id: nil, exit_page_id: exit_page.id }

      it "returns nil" do
        expect(condition.warning_goto_page_doesnt_exist).to be_nil
      end
    end
  end

  describe "#warning_answer_doesnt_exist" do
    let(:form) { create :form }
    let(:check_page) { create :page, :with_selection_settings, form: }
    let(:goto_page) { create :page, form: }
    let(:condition) do
      create(
        :condition,
        routing_page_id: check_page.id,
        check_page_id: check_page.id,
        goto_page_id: goto_page.id,
        answer_value: check_page.answer_settings["selection_options"].first["name"],
      )
    end

    it "returns nil if answer exists" do
      expect(condition.warning_answer_doesnt_exist).to be_nil
    end

    context "when answer has been deleted from page" do
      it "returns object with error short name code" do
        condition.check_page.answer_settings["selection_options"].shift
        expect(condition.warning_answer_doesnt_exist).to eq(DataStruct.new(name: "answer_value_doesnt_exist"))
      end
    end

    context "when answer on the page has been updated" do
      it "returns object with error short name code" do
        condition.check_page.answer_settings["selection_options"].first["name"] = "Option 1.2"
        expect(condition.warning_answer_doesnt_exist).to eq(DataStruct.new(name: "answer_value_doesnt_exist"))
      end
    end

    context "when answer_value is 'None of the above" do
      let(:condition) { create :condition, routing_page_id: check_page.id, check_page_id: check_page.id, goto_page_id: goto_page.id, answer_value: Condition::NONE_OF_THE_ABOVE }
      let(:check_page) { create :page, :with_selection_settings, form:, is_optional: }

      context "and routing page has 'None of the above' as an option" do
        let(:is_optional) { true }

        it "returns nil" do
          expect(condition.warning_answer_doesnt_exist).to be_nil
        end
      end

      context "and routing page does not have 'None of the above' as an option" do
        let(:is_optional) { false }

        it "returns object with error short name code" do
          expect(condition.warning_answer_doesnt_exist).to eq(DataStruct.new(name: "answer_value_doesnt_exist"))
        end
      end
    end

    context "when condition is a after another condition for a branch route" do
      let(:routing_page) { create :page, form: }
      let(:after_condition) do
        create(
          :condition,
          answer_value: nil,
          check_page_id: condition.check_page_id,
          routing_page_id: routing_page.id,
          skip_to_end: true,
        )
      end

      it "returns nil" do
        expect(after_condition.warning_answer_doesnt_exist).to be_nil
      end
    end
  end

  describe "#warning_routing_to_next_page" do
    let(:form) { build :form, pages: [check_page, current_page, next_page, last_page] }
    let(:check_page) { build :page, position: 1 }
    let(:current_page) { build :page, position: 2 }
    let(:next_page) { build :page, position: 3 }
    let(:last_page) { build :page, position: 4 }

    shared_examples "returns no warning" do
      it "returns nil" do
        expect(condition.warning_routing_to_next_page).to be_nil
      end
    end

    shared_examples "returns routing warning" do
      it "returns cannot_route_to_next_page warning" do
        expect(condition.warning_routing_to_next_page).to eq(DataStruct.new(name: "cannot_route_to_next_page"))
      end
    end

    context "when routing to a non-adjacent page" do
      let(:condition) do
        create :condition,
               routing_page: current_page,
               check_page: check_page,
               goto_page: last_page
      end

      it_behaves_like "returns no warning"
    end

    context "when routing to the next sequential page" do
      let(:condition) do
        create :condition,
               routing_page: current_page,
               check_page: check_page,
               goto_page: next_page
      end

      it_behaves_like "returns routing warning"
    end

    context "with nil values" do
      context "when goto_page is nil" do
        let(:condition) do
          create :condition,
                 routing_page: current_page,
                 check_page: check_page,
                 goto_page: nil
        end

        it_behaves_like "returns no warning"
      end

      context "when check_page is nil" do
        let(:condition) do
          create :condition,
                 routing_page: current_page,
                 check_page: nil,
                 goto_page: next_page
        end

        it_behaves_like "returns no warning"
      end
    end

    context "with skip_to_end functionality" do
      context "when routing from the last page" do
        let(:condition) do
          create :condition,
                 routing_page: last_page,
                 check_page: check_page,
                 goto_page: nil,
                 skip_to_end: true
        end

        it_behaves_like "returns routing warning"
      end

      context "when routing from a non-last page" do
        let(:condition) do
          create :condition,
                 routing_page: current_page,
                 check_page: check_page,
                 goto_page: nil,
                 skip_to_end: false
        end

        it_behaves_like "returns no warning"
      end
    end

    context "with non-sequential page positions" do
      let(:current_page) { build :page, position: 2 }
      let(:next_page) { build :page, position: 4 }
      let(:condition) do
        create :condition,
               routing_page: current_page,
               check_page: check_page,
               goto_page: next_page
      end

      it_behaves_like "returns no warning"
    end
  end

  describe "#warning_goto_page_before_routing_page" do
    let(:form) { build :form, pages: [previous_page, current_page, next_page, last_page] }
    let(:check_page) { build :page, position: 1 }
    let(:previous_page) { build :page, position: 2 }
    let(:current_page) { build :page, position: 3 }
    let(:next_page) { build :page, position: 4 }
    let(:last_page) { build :page, position: 5 }

    shared_examples "returns no warning" do
      it "returns nil" do
        expect(condition.warning_goto_page_before_routing_page).to be_nil
      end
    end

    shared_examples "returns routing warning" do
      it "returns cannot_have_goto_page_before_routing_page warning" do
        expect(condition.warning_goto_page_before_routing_page).to(
          eq(DataStruct.new(name: "cannot_have_goto_page_before_routing_page")),
        )
      end
    end

    context "when routing to a later page" do
      let(:condition) do
        create :condition,
               routing_page: current_page,
               check_page: current_page,
               goto_page: last_page
      end

      it_behaves_like "returns no warning"
    end

    context "when routing to a previous page" do
      let(:condition) do
        create :condition,
               routing_page: current_page,
               check_page: current_page,
               goto_page: previous_page
      end

      it_behaves_like "returns routing warning"
    end

    context "with nil values" do
      context "when goto_page is nil" do
        context "with skip_to_end false" do
          let(:condition) do
            create :condition,
                   routing_page: current_page,
                   check_page: current_page,
                   goto_page: nil,
                   skip_to_end: false
          end

          it_behaves_like "returns no warning"
        end

        context "with skip_to_end true" do
          let(:condition) do
            create :condition,
                   routing_page: current_page,
                   check_page: current_page,
                   goto_page: nil,
                   skip_to_end: true
          end

          it_behaves_like "returns no warning"
        end
      end
    end

    context "when routing to the same position" do
      let(:same_position_page) { build :page, position: 3 }
      let(:condition) do
        create :condition,
               routing_page: current_page,
               check_page: current_page,
               goto_page: same_position_page
      end

      it_behaves_like "returns routing warning"
    end

    context "with non-sequential page positions" do
      let(:gap_page) { build :page, position: 6 }
      let(:condition) do
        create :condition,
               routing_page: current_page,
               check_page: current_page,
               goto_page: gap_page
      end

      it_behaves_like "returns no warning"
    end
  end

  describe "#is_end_of_form?" do
    let(:form) { create :form }
    let(:check_page) { create :page, :with_selection_settings, form: }
    let(:goto_page) { create :page, form: }

    context "when goto page is nil and skip_to_end is false" do
      let(:condition) { create :condition, routing_page_id: check_page.id, check_page_id: check_page.id, goto_page_id: nil, skip_to_end: false }

      it "returns nil" do
        expect(condition.is_end_of_form?).to be false
      end
    end

    context "when goto page is nil and skip_to_end is true" do
      let(:condition) { create :condition, routing_page_id: check_page.id, check_page_id: check_page.id, goto_page_id: nil, skip_to_end: true }

      it "returns nil" do
        expect(condition.is_end_of_form?).to be true
      end
    end

    context "when goto page has a value and skip_to_end is false" do
      let(:condition) { create :condition, routing_page_id: check_page.id, check_page_id: check_page.id, goto_page_id: goto_page.id, skip_to_end: false }

      it "returns nil" do
        expect(condition.is_end_of_form?).to be false
      end
    end

    context "when goto page has a value and skip_to_end is true" do
      let(:condition) { create :condition, routing_page_id: check_page.id, check_page_id: check_page.id, goto_page_id: goto_page.id, skip_to_end: true }

      it "returns nil" do
        expect(condition.is_end_of_form?).to be false
      end
    end
  end

  describe "#has_routing_errors" do
    let(:form) { create :form }
    let(:goto_page) { create :page, form: }
    let(:goto_page_id) { goto_page.id }
    let(:routing_page) { create :page, form: }
    let(:condition) { create :condition, routing_page_id: routing_page.id, goto_page_id: }

    context "when there are no validation errors" do
      it "returns false" do
        expect(condition.has_routing_errors).to be false
      end
    end

    context "when there are validation errors" do
      let(:goto_page_id) { nil }

      it "returns true" do
        expect(condition.has_routing_errors).to be true
      end
    end
  end

  describe "#errors_with_fields" do
    let(:condition) { create(:condition, check_page:, answer_value: nil, goto_page_id: nil) }
    let(:check_page) { create(:page, :with_selection_settings) }

    context "when the error is a known error" do
      it "returns the correct values for each error type" do
        expect(condition.errors_with_fields).to contain_exactly({ field: :answer_value, name: "answer_value_doesnt_exist" }, { field: :goto_page_id, name: "goto_page_doesnt_exist" })
      end
    end
  end

  describe "#as_json" do
    let(:form) { create :form }
    let(:check_page) { create :page, :with_selection_settings, form: }
    let(:goto_page) { create :page, form: }
    let(:condition) { create :condition, routing_page_id: check_page.id, check_page_id: check_page.id, goto_page_id: goto_page.id, skip_to_end: false }

    it "returns a json object" do
      expect(condition.as_json).to match({
        "id" => condition.id,
        "check_page_id" => check_page.id,
        "routing_page_id" => check_page.id,
        "goto_page_id" => goto_page.id,
        "answer_value" => nil,
        "created_at" => a_kind_of(String),
        "updated_at" => a_kind_of(String),
        "skip_to_end" => false,
        "exit_page_markdown" => nil,
        "exit_page_heading" => nil,
        "validation_errors" => [
          { "name" => "answer_value_doesnt_exist" },
          { "name" => "cannot_route_to_next_page" },
        ],
        "has_routing_errors" => true,
        "exit_page_id" => nil,
      })
    end

    context "when the condition has an ExitPage" do
      let(:exit_page) { create :exit_page, question_page: check_page }
      let(:condition) { create :condition, exit_page_id: exit_page.id, routing_page_id: check_page.id }

      it "includes the exit_page_id" do
        expect(condition.as_json).to include({
          "exit_page_id" => condition.exit_page.id,
        })
      end
    end
  end

  describe "#as_form_document_condition" do
    let(:form) { create :form }
    let(:check_page) { create :page, :with_selection_settings, form: }
    let(:routing_page) { create :page, :with_selection_settings, form: }
    let(:goto_page) { create :page, form: }
    let(:condition) { create :condition, routing_page_id: routing_page.id, check_page_id: check_page.id, goto_page_id: goto_page.id, skip_to_end: false }

    it "returns a json object" do
      expect(condition.as_form_document_condition).to match({
        "id" => condition.id,
        "check_page_id" => check_page.external_id,
        "routing_page_id" => routing_page.external_id,
        "goto_page_id" => goto_page.external_id,
        "answer_value" => nil,
        "created_at" => a_kind_of(String),
        "updated_at" => a_kind_of(String),
        "skip_to_end" => false,
        "exit_page_markdown" => nil,
        "exit_page_heading" => nil,
        "validation_errors" => [
          { "name" => "answer_value_doesnt_exist" },
        ],
        "exit_page_id" => nil,
      })
    end
  end

  describe "#normalise_welsh!" do
    context "when the condition is destroyed" do
      it "does not raise an error" do
        condition.destroy!
        expect { condition.normalise_welsh! }.not_to raise_error
      end
    end

    context "when the condition is an exit page" do
      subject(:condition) { create :condition, :with_exit_page, exit_page_heading_cy: "Welsh heading", exit_page_markdown_cy: "Welsh markdown" }

      it "doesn't clear Welsh" do
        condition.normalise_welsh!
        expect(condition.reload.exit_page_heading_cy).to eq("Welsh heading")
        expect(condition.reload.exit_page_markdown_cy).to eq("Welsh markdown")
      end
    end

    context "when the condition is not an exit page" do
      subject(:condition) { create :condition, exit_page_heading_cy: "Welsh heading", exit_page_markdown_cy: "Welsh markdown" }

      it "clears Welsh" do
        condition.normalise_welsh!
        expect(condition.reload.exit_page_heading_cy).to be_nil
        expect(condition.reload.exit_page_markdown_cy).to be_nil
      end
    end
  end
end
