require "rails_helper"

RSpec.describe Page, type: :model do
  subject(:page) { create :page, :with_selection_settings, form:, routing_conditions:, check_conditions: }

  let(:form) { create :form }
  let(:routing_conditions) { [] }
  let(:check_conditions) { [] }

  it "has a valid factory" do
    page = create :page
    expect(page).to be_valid
  end

  shared_examples "update form state" do
    context "when the form is live" do
      let(:form) { create(:form, :live) }

      it "updates the form state to live_with_draft" do
        expect(form.state).to eq("live_with_draft")
      end
    end

    context "when the form is archived" do
      let(:form) { create(:form, :archived) }

      it "updates the form state to archived_with_draft" do
        expect(form.state).to eq("archived_with_draft")
      end
    end
  end

  describe "associations" do
    let(:form) { create :form }
    let(:page) { create :page, form: }

    context "when it has a routing condition" do
      let!(:condition) { page.routing_conditions.create! }

      it "deletes the condition if it is deleted" do
        page.destroy!

        expect(condition).to be_destroyed
      end
    end

    context "when it has a check condition" do
      let(:routing_page) { create :page, form: }
      let!(:condition) { page.check_conditions.create! routing_page: }

      it "deletes the condition if it is deleted" do
        page.destroy!

        expect(condition).to be_destroyed
      end
    end

    context "when it has a go to condition" do
      let(:routing_page) { create :page, form: }
      let!(:condition) { page.goto_conditions.create! routing_page: }

      it "removes association from the condition if it is deleted" do
        page.destroy!

        expect(condition).to be_destroyed
        expect(condition.goto_page).to be_nil
      end

      context "and the routing page has a secondary skip condition" do
        let(:end_of_first_branch) { create :page, form: }
        let!(:condition) { page.goto_conditions.create! routing_page:, check_page: routing_page }
        let!(:secondary_skip_condition) { routing_page.check_conditions.create! routing_page: end_of_first_branch, skip_to_end: true }

        it "deletes the secondary skip condition if it is deleted" do
          expect {
            page.destroy!
          }.to change(Condition, :count).by(-2)

          expect(condition).to be_destroyed
          expect(Condition).not_to exist(secondary_skip_condition.id)
        end
      end

      context "and the routing page has other routing conditions" do
        let!(:condition) { page.goto_conditions.create! routing_page:, check_page: routing_page }
        let!(:other_condition) { routing_page.routing_conditions.create! routing_page:, check_page: routing_page, skip_to_end: true }

        it "does not deletes the other conditions if it is deleted" do
          expect {
            page.destroy!
          }.to change(Condition, :count).by(-1)

          expect(condition).to be_destroyed
          expect(Condition).to exist(other_condition.id)
        end
      end
    end

    context "when the form has a branching route with skip and secondary skip" do
      let(:branch_question) { create :page, form: }
      let(:end_of_first_branch) { create :page, form: }
      let(:start_of_second_branch) { create :page, form: }
      let(:end_of_branches) { create :page, form: }

      let!(:skip_condition) do
        create :condition, routing_page: branch_question, check_page: branch_question, goto_page: start_of_second_branch
      end
      let!(:secondary_skip_condition) do
        create :condition, routing_page: end_of_first_branch, check_page: branch_question, goto_page: end_of_branches
      end

      before do
        branch_question.reload
        end_of_first_branch.reload
        start_of_second_branch.reload
        end_of_branches.reload
      end

      context "and the branch question has been deleted" do
        it "deletes all the conditions" do
          expect {
            branch_question.destroy!
          }.to change(Condition, :count).from(2).to(0)

          expect(Condition).not_to exist(skip_condition.id)
          expect(Condition).not_to exist(secondary_skip_condition.id)
        end
      end

      context "and the question at the start of the second branch has been deleted" do
        it "deletes all the conditions" do
          expect {
            start_of_second_branch.destroy!
          }.to change(Condition, :count).from(2).to(0)

          expect(Condition).not_to exist(skip_condition.id)
          expect(Condition).not_to exist(secondary_skip_condition.id)
        end
      end

      context "and the question at the end of the branches has been deleted" do
        it "deletes the secondary skip condition" do
          expect {
            end_of_branches.destroy!
          }.to change(Condition, :count).from(2).to(1)

          expect(Condition).to exist(skip_condition.id)
          expect(Condition).not_to exist(secondary_skip_condition.id)
        end
      end

      context "and the question at the end of the first branch has been deleted" do
        it "deletes the secondary skip condition" do
          expect {
            end_of_first_branch.destroy!
          }.to change(Condition, :count).from(2).to(1)

          expect(Condition).to exist(skip_condition.id)
          expect(Condition).not_to exist(secondary_skip_condition.id)
        end
      end
    end
  end

  describe "validations" do
    it "validates" do
      page.question_text = "Example question"
      page.answer_type = "national_insurance_number"
      expect(page).to be_valid
    end

    describe "#question_text" do
      let(:page) { build :page, question_text: }
      let(:question_text) { "What is your address?" }

      it "is required" do
        page.question_text = nil
        expect(page).to be_invalid
        expect(page.errors[:question_text]).to include("Enter a question")
      end

      it "is valid if question text below 250 characters" do
        expect(page).to be_valid
      end

      context "when question text 250 characters" do
        let(:question_text) { "A" * 250 }

        it "is valid" do
          expect(page).to be_valid
        end
      end

      context "when question text more 250 characters" do
        let(:question_text) { "A" * 251 }

        it "is invalid" do
          expect(page).not_to be_valid
        end

        it "has an error message" do
          page.valid?
          expect(page.errors[:question_text]).to include("Question text must be 250 characters or less")
        end
      end
    end

    describe "#hint_text" do
      let(:page) { build :page, hint_text: }
      let(:hint_text) { "Enter your full name as it appears in your passport" }

      it "is valid if hint text is empty" do
        page.hint_text = nil
        expect(page).to be_valid
      end

      it "is valid if hint text below 500 characters" do
        expect(page).to be_valid
      end

      context "when hint text 500 characters" do
        let(:hint_text) { "A" * 500 }

        it "is valid" do
          expect(page).to be_valid
        end
      end

      context "when hint text more than 500 characters" do
        let(:hint_text) { "A" * 501 }

        it "is invalid" do
          expect(page).not_to be_valid
        end

        it "has an error message" do
          page.valid?
          expect(page.errors[:hint_text]).to include("Hint text must be 500 characters or less")
        end
      end
    end

    it "requires form" do
      page.form_id = nil
      expect(page).to be_invalid
      expect(page.errors[:form]).to include("must exist")
    end

    it "requires answer_type" do
      page.answer_type = nil
      expect(page).to be_invalid
      expect(page.errors[:answer_type]).to include("can't be blank")
    end

    it "requires answer_type to be in list" do
      page.answer_type = "unknown_type"
      expect(page).to be_invalid
      expect(page.errors[:answer_type]).to include("is not included in the list")
    end

    context "when guidance_fields are provided" do
      it "requires guidance_markdown if page_heading is present" do
        page.page_heading = "My new page heading"
        expect(page).to be_invalid
        expect(page.errors[:guidance_markdown]).to include("must be present when Page Heading is present")
      end

      it "requires page_heading if guidance_markdown is present" do
        page.guidance_markdown = "Some extra guidance for this question"
        expect(page).to be_invalid
        expect(page.errors[:page_heading]).to include("must be present when Guidance Markdown is present")
      end

      describe "page_heading length validations" do
        let(:page) { build :page, :with_guidance, page_heading: }
        let(:page_heading) { "What is your address?" }

        it "is valid if page heading below 500 characters" do
          expect(page).to be_valid
        end

        context "when page heading 250 characters" do
          let(:page_heading) { "A" * 250 }

          it "is valid" do
            expect(page).to be_valid
          end
        end

        context "when page_heading more than 250 characters" do
          let(:page_heading) { "A" * 251 }

          it "is invalid" do
            expect(page).not_to be_valid
          end

          it "has an error message" do
            page.valid?
            expect(page.errors[:page_heading]).to include("Page heading must be 250 characters or less")
          end
        end
      end

      context "when markdown is too long" do
        it "adds an error to guidance_markdown" do
          page.guidance_markdown = "ABC" * 5000
          expect(page).to be_invalid
          expect(page.errors[:guidance_markdown]).to include("is too long (maximum is 4,999 characters)")
        end
      end

      context "when markdown is using unsupported syntax" do
        it "adds error to guidance_markdown" do
          page.guidance_markdown = "# Heading level 1"
          expect(page).to be_invalid
          expect(page.errors[:guidance_markdown]).to include("can only contain formatting for links, subheadings(##), bulleted listed (*), or numbered lists(1.)")
        end
      end

      context "when markdown is using unsupported syntax which is too long" do
        it "adds error to guidance_markdown" do
          page.guidance_markdown = "# Heading level 1\n\n" * 5000
          expect(page).to be_invalid
          expect(page.errors[:guidance_markdown]).to include("can only contain formatting for links, subheadings(##), bulleted listed (*), or numbered lists(1.)")
          expect(page.errors[:guidance_markdown]).to include("is too long (maximum is 4,999 characters)")
        end
      end
    end
  end

  describe "translations" do
    let(:translated_attributes) do
      %i[question_text hint_text page_heading guidance_markdown]
    end

    it "can set and read translated attributes for :en and :cy locales" do
      Mobility.with_locale(:en) do
        page.answer_settings = { "only_one_option" => "true", "selection_options" => [{ name: "Option 1 english" }, { name: "Option 2 english" }] }
        translated_attributes.each do |attribute|
          page.send("#{attribute}=", "english_#{attribute}")
        end
        page.save!
      end

      Mobility.with_locale(:cy) do
        page.answer_settings = { "only_one_option" => "false", "selection_options" => [{ name: "Option 1 welsh" }, { name: "Option 2 welsh" }] }
        translated_attributes.each do |attribute|
          page.send("#{attribute}=", "welsh_#{attribute}")
        end
        page.save!
      end

      Mobility.with_locale(:en) do
        page.reload
        expect(page.answer_settings["selection_options"]).to eq([DataStruct.new(name: "Option 1 english"), DataStruct.new(name: "Option 2 english")])
        translated_attributes.each do |attribute|
          expect(page.send(attribute)).to eq("english_#{attribute}")
        end
      end

      Mobility.with_locale(:cy) do
        page.reload
        expect(page.answer_settings["selection_options"]).to eq([DataStruct.new(name: "Option 1 welsh"), DataStruct.new(name: "Option 2 welsh")])
        translated_attributes.each do |attribute|
          expect(page.send(attribute)).to eq("welsh_#{attribute}")
        end
      end
    end
  end

  describe "before_create" do
    it "sets the external_id" do
      page = create :page
      expect(page.external_id).to be_present
    end
  end

  describe ".create_and_update_form!" do
    let(:form) { create(:form, question_section_completed: true) }
    let(:page_params) do
      { form_id: form.id,
        question_text: "What is the name of your organisation?",
        hint_text: "Some hint text",
        is_optional: true,
        is_repeatable: false,
        answer_settings:,
        page_heading: "A page heading",
        guidance_markdown: "some guidance markdown",
        answer_type: }
    end
    let(:answer_type) { "organisation_name" }
    let(:answer_settings) { {} }

    it "creates a page" do
      expect {
        described_class.create_and_update_form!(**page_params)
      }.to change(described_class, :count).by(1)
    end

    it "creates with the parameters provided" do
      page = described_class.create_and_update_form!(**page_params)
      expect(page.question_text).to eq(page_params[:question_text])
      expect(page.hint_text).to eq(page_params[:hint_text])
      expect(page.is_optional).to eq(page_params[:is_optional])
      expect(page.is_repeatable).to eq(page_params[:is_repeatable])
      expect(page.page_heading).to eq(page_params[:page_heading])
      expect(page.guidance_markdown).to eq(page_params[:guidance_markdown])
      expect(page.answer_type).to eq(page_params[:answer_type])
    end

    it "returns the page" do
      expect(described_class.create_and_update_form!(**page_params)).to be_a(described_class)
    end

    it "associates the page with a form" do
      described_class.create_and_update_form!(**page_params)
      expect(described_class.last.form).to eq(form)
    end

    context "when the form question section is complete" do
      let(:form) { create(:form, :live, question_section_completed: true) }

      it "updates the form to mark the question section as incomplete" do
        expect {
          described_class.create_and_update_form!(**page_params)
        }.to change { form.reload.question_section_completed }.to(false)
      end

      it "changes the form to live_with_draft" do
        expect {
          described_class.create_and_update_form!(**page_params)
        }.to change { form.reload.state }.to("live_with_draft")
      end
    end

    context "when the page has answer settings" do
      let(:answer_type) { "selection" }
      let(:answer_settings) { { only_one_option: "true", selection_options: [] } }

      it "saves the answer settings to the database" do
        described_class.create!(**page_params)
        expect(described_class.last).to have_attributes(
          "answer_settings" => DataStruct.new({
            "only_one_option" => "true",
            "selection_options" => [],
          }),
        )
      end
    end
  end

  describe "#destroy_and_update_form!" do
    let(:form) { create :form, :live, question_section_completed: true }
    let(:page) { create :page, form: }

    it "sets form.question_section_completed to false" do
      expect {
        page.destroy_and_update_form!
      }.to change { form.reload.question_section_completed }.to(false)
    end

    it "changes the form to live_with_draft" do
      expect {
        page.destroy_and_update_form!
      }.to change { form.reload.state }.to("live_with_draft")
    end
  end

  describe "#save_and_update_form" do
    it "sets form.question_section_completed to false" do
      page.question_text = "Edited question"
      page.save_and_update_form
      expect(form.question_section_completed).to be false
    end

    it_behaves_like "update form state" do
      before do
        page.question_text = "Edited question"
        page.save_and_update_form
      end
    end

    context "when page has routing conditions and ExitPages" do
      let(:routing_conditions) { [create(:condition, exit_page:)] }
      let(:check_conditions) { routing_conditions }
      let(:exit_page) { create :exit_page }

      before do
        exit_page.question_page = page
        exit_page.save!
      end

      it "does not delete existing conditions or ExitPages" do
        page.save_and_update_form
        expect(page.reload.routing_conditions.to_a).to eq(routing_conditions)
        expect(page.reload.check_conditions.to_a).to eq(check_conditions)
        expect(page.reload.exit_pages.to_a).to eq([exit_page])
      end

      context "when answer type is updated to one doesn't support routing" do
        it "deletes any conditions" do
          page.answer_type = "number"
          page.save_and_update_form
          expect(page.reload.check_conditions).to be_empty
        end

        it "deletes any ExitPages" do
          page.answer_type = "number"
          page.save_and_update_form
          expect(page.reload.exit_pages).to be_empty
        end
      end

      context "when the page is saved without changing the answer type" do
        it "does not delete the conditions or ExitPages" do
          page.question_text = "test"
          page.save_and_update_form
          expect(page.reload.check_conditions).not_to be_empty
          expect(page.reload.exit_pages).not_to be_empty
        end
      end

      context "when the answer settings no longer restrict to only one option" do
        it "deletes any conditions" do
          page.answer_settings["only_one_option"] = "0"
          page.save_and_update_form
          expect(page.reload.check_conditions).to be_empty
        end

        it "deletes any ExitPages" do
          page.answer_settings["only_one_option"] = "0"
          page.save_and_update_form
          expect(page.reload.exit_pages).to be_empty
        end
      end

      context "when the answer settings change while still restricting to only one option" do
        it "does not delete any conditions or ExitPages" do
          page.answer_settings["selection_options"].first["name"] = "New option name"
          page.save_and_update_form
          expect(page.reload.check_conditions).not_to be_empty
          expect(page.reload.exit_pages).not_to be_empty
        end
      end

      context "when the answer type changes from selection with more than one option" do
        subject(:page) { create :page, :selection_with_checkboxes, form:, routing_conditions:, check_conditions: }

        it "does not delete any conditions" do
          page.answer_type = "number"
          page.save_and_update_form
          expect(page.reload.check_conditions).not_to be_empty
        end
      end
    end
  end

  describe "#move_page" do
    let(:form) { create :form, :with_pages, question_section_completed: true }
    let(:page) { form.pages.second }

    context "when direction is up" do
      it "moves the page towards the front of the form" do
        expect {
          page.move_page(:up)
        }.to change(page, :position).by(-1)
      end

      it "sets form.question_section_completed to false" do
        page.move_page(:up)
        expect(form.question_section_completed).to be false
      end

      it_behaves_like "update form state" do
        before do
          page.move_page(:up)
        end
      end

      context "when the page is already the first page in the form" do
        let(:page) { form.pages.first }

        it "does not change the position of the page" do
          expect {
            page.move_page(:up)
          }.not_to change(page, :position)
        end

        it "sets form.question_section_completed to false" do
          page.move_page(:up)
          expect(form.question_section_completed).to be false
        end
      end
    end

    context "when direction is down" do
      it "moves the page towards the end of the form" do
        expect {
          page.move_page(:down)
        }.to change(page, :position).by(1)
      end

      it "sets form.question_section_completed to false" do
        page.move_page(:down)
        expect(form.question_section_completed).to be false
      end

      it_behaves_like "update form state" do
        before do
          page.move_page(:down)
        end
      end

      context "when the page is already the last page in the form" do
        let(:page) { form.pages.last }

        it "does not change the position of the page" do
          expect {
            page.move_page(:down)
          }.not_to change(page, :position)
        end

        it "sets form.question_section_completed to false" do
          page.move_page(:down)
          expect(form.question_section_completed).to be false
        end
      end
    end

    context "when direction is neither up nor down" do
      it "does not move the page" do
        expect {
          page.move_page(:left)
        }.not_to change(page, :position)
      end

      it "does not set form.question_section_completed to false" do
        page.move_page(:left)
        expect(form.question_section_completed).to be true
      end
    end
  end

  describe "next_page" do
    context "when there is no next page" do
      it "returns nil" do
        expect(page.next_page).to be_nil
      end
    end

    context "when there is a next page" do
      let!(:next_page) { create :page, form: page.form }

      it "returns the next page" do
        expect(page.next_page).to eq(next_page.id)
      end
    end
  end

  describe "#has_next_page?" do
    context "when there is no next page" do
      it "returns false" do
        expect(page.has_next_page?).to be false
      end
    end

    context "when there is a next page" do
      before do
        create :page, form: page.form
      end

      it "returns true" do
        expect(page.has_next_page?).to be true
      end
    end
  end

  describe "#has_routing_errors" do
    subject(:page) { build :page, :with_selection_settings, routing_conditions: [condition] }

    let(:condition) { build :condition }
    let(:has_routing_errors) { false }

    before do
      allow(condition).to receive(:has_routing_errors).and_return(has_routing_errors)
    end

    context "when there are no validation errors" do
      it "returns false" do
        expect(page.has_routing_errors).to be false
      end
    end

    context "when there are validation errors" do
      let(:has_routing_errors) { true }

      it "returns true" do
        expect(page.has_routing_errors).to be true
      end
    end
  end

  describe "#answer_settings" do
    context "when the answer_settings are a Hash" do
      let(:page) { build :page, answer_settings: { "first_key" => "first_keys_value", "second_key" => { "third_key" => "third_keys_value" } } }

      it "returns an OpenStruct with the answer settings" do
        expect(page.answer_settings).to be_a(OpenStruct)
        expect(page.answer_settings.first_key).to eq("first_keys_value")
        expect(page.answer_settings.second_key.third_key).to eq("third_keys_value")
      end
    end
  end

  describe "#question_with_number" do
    let(:page) { described_class.new(question_text: "What's your name?", position: 5) }

    it "returns the page number and question text as a string" do
      expect(page.question_with_number).to eq("#{page.position}. #{page.question_text}")
    end
  end

  describe "#show_optional_suffix?" do
    let(:page) { described_class.new(is_optional:, answer_type:) }
    let(:is_optional) { "true" }
    let(:answer_type) { "national_insurance_number" }

    context "when question is optional and answer type is not selection" do
      it "returns true" do
        expect(page.show_optional_suffix?).to be true
      end
    end

    context "when question is optional and has answer_type selection" do
      let(:answer_type) { "selection" }

      it "returns false" do
        expect(page.show_optional_suffix?).to be false
      end
    end

    context "when question is not optional and answer type is not selection" do
      let(:is_optional) { "false" }

      it "returns false" do
        expect(page.show_optional_suffix?).to be false
      end
    end
  end

  describe "#as_form_document_step" do
    let!(:page) { create :page, form: }
    let!(:second_page) { create :page, form: }

    it "has an id which is the page's external_id" do
      expect(page.as_form_document_step(second_page)).to match a_hash_including("id" => page.external_id)
    end

    it "has a position" do
      expect(page.as_form_document_step(second_page)).to match a_hash_including("position" => page.position)
    end

    it "has a next_step_id which is the external ID of the next page" do
      expect(page.as_form_document_step(second_page)).to match a_hash_including("next_step_id" => second_page.external_id)
    end

    it "does not include the external_id" do
      expect(page.as_form_document_step(second_page)).not_to have_key("external_id")
    end

    it "includes all attributes for the page as a step" do
      page_attributes = described_class.attribute_names - %w[id external_id form_id next_page position created_at updated_at]
      expect(page.as_form_document_step(second_page)["data"]).to match a_hash_including(*page_attributes)
    end

    it "includes exit_pages as an array" do
      expect(page.as_form_document_step(second_page)["exit_pages"]).to be_a(Array)
    end

    context "when there are conditions associated with the page" do
      let!(:condition) { create :condition, routing_page_id: page.id, check_page_id: page.id }

      it "includes the routing conditions" do
        expect(page.reload.as_form_document_step(second_page)["routing_conditions"]).to include(condition.as_form_document_condition)
      end
    end

    context "when the provided next_page is nil" do
      it "has nil next_step_id" do
        expect(page.as_form_document_step(nil)["next_step_id"]).to be_nil
      end
    end

    context "when the page has an ExitPage" do
      let!(:exit_page) { create :exit_page, question_page: page }

      before do
        create(:condition, routing_page_id: page.id, check_page_id: page.id, exit_page:)
      end

      it "includes the exit page" do
        expect(page.reload.as_form_document_step(second_page)["exit_pages"].first).to match a_hash_including("id" => exit_page.id, "markdown" => exit_page.markdown, "heading" => exit_page.heading)
      end
    end
  end

  describe "#secondary_skip_condition" do
    let(:form) { create :form, :ready_for_routing }
    let(:page) { form.pages.second }

    before do
      # create some conditions that won't be returned
      create(:condition, routing_page: page, check_page: page, goto_page: form.pages.fifth, answer_value: "Option 1")
      create(:condition, routing_page: page, check_page: page, goto_page: form.pages.fifth, answer_value: nil)
    end

    context "when there is a secondary skip condition" do
      let!(:secondary_skip_condition) { create :condition, routing_page: form.pages.third, check_page: page, goto_page: form.pages.fourth }

      it "returns the secondary skip condition" do
        expect(page.secondary_skip_condition).to eq secondary_skip_condition
      end
    end

    context "when there are no secondary skip conditions" do
      it "returns nil" do
        expect(page.secondary_skip_condition).to be_nil
      end
    end
  end

  describe "#normalise_welsh!" do
    let!(:page) { create(:page, form: create(:form)) }

    context "when the page is destroyed" do
      it "does not raise an error" do
        page.destroy!
        expect { page.normalise_welsh! }.not_to raise_error
      end
    end

    context "with hint text" do
      context "when hint_text (English) is present" do
        before do
          page.update!(hint_text: "English hint")
          page.update!(hint_text_cy: "Welsh hint")
          page.normalise_welsh!
        end

        it "does not clear the Welsh hint text" do
          expect(page.reload.hint_text_cy).to eq "Welsh hint"
        end
      end

      context "when hint_text (English) is blank" do
        before do
          page.update!(hint_text: "")
          page.update!(hint_text_cy: "Welsh hint")
          page.normalise_welsh!
        end

        it "clears the Welsh hint text" do
          expect(page.reload.hint_text_cy).to be_nil
        end
      end
    end

    context "with guidance fields" do
      let(:welsh_page_heading) { "Welsh heading" }
      let(:welsh_guidance_markdown) { "Welsh markdown" }

      before do
        page.update!(
          page_heading_cy: welsh_page_heading,
          guidance_markdown_cy: welsh_guidance_markdown,
        )
      end

      context "when page_heading and guidance_markdown (English) are present" do
        before do
          page.update!(
            page_heading: "English heading",
            guidance_markdown: "English markdown",
          )
          page.normalise_welsh!
        end

        it "does not clear the Welsh guidance fields" do
          page.reload
          expect(page.page_heading_cy).to eq welsh_page_heading
          expect(page.guidance_markdown_cy).to eq welsh_guidance_markdown
        end
      end

      context "when page_heading and guidance_markdown (English) are blank" do
        before do
          page.update!(
            page_heading: "",
            guidance_markdown: "",
          )
          page.normalise_welsh!
        end

        it "clears the Welsh guidance fields" do
          page.reload
          expect(page.page_heading_cy).to be_nil
          expect(page.guidance_markdown_cy).to be_nil
        end
      end
    end

    context "when the page has conditions" do
      let!(:condition) { page.routing_conditions.create! }

      it "normalises the conditions" do
        allow(condition).to receive(:normalise_welsh!)
        page.normalise_welsh!
        expect(condition).to have_received(:normalise_welsh!)
      end
    end
  end

  describe "#page_position_id" do
    it "returns a string for the page position id" do
      expect(page.page_position_id).to eq "page-#{page.position}"
    end
  end
end
