require "rails_helper"

RSpec.describe Reports::FeatureReportService do
  let(:forms) do
    [
      form_with_all_answer_types,
      form_with_a_few_answer_types,
      branch_route_form,
      basic_route_form,
      copied_form,
      form_with_a_welsh_translation,
    ]
  end
  let(:form_documents) do
    forms.map do |form|
      # FormDocumentsService adds in the welsh_completed details as part of the database query
      form.live_form_document.as_json
          .merge({
            "welsh_completed" => form.welsh_completed,
          })
    end
  end
  let_it_be(:group) { create(:group) }

  let_it_be(:form_with_all_answer_types) do
    create(:form, :live,
           :with_support,
           submission_type: "email",
           submission_format: %w[csv],
           payment_url: "https://www.gov.uk/payments/organisation/service",
           send_copy_of_answers: "enabled",
           pages: [
             create(:page, :with_address_settings, is_repeatable: true),
             create(:page, :with_date_settings),
             create(:page, answer_type: "email"),
             create(:page, :with_full_name_settings),
             create(:page, answer_type: "national_insurance_number"),
             create(:page, answer_type: "number"),
             create(:page, answer_type: "phone_number"),
             create(:page, :with_selection_settings, is_optional: true),
             create(:page, :with_single_line_text_settings, is_repeatable: true),
           ])
  end
  let_it_be(:form_with_a_few_answer_types) do
    create(:form,
           :live,
           submission_type: "email",
           submission_format: %w[csv json],
           send_daily_submission_batch: true,
           send_weekly_submission_batch: true,
           pages: [
             create(:page, answer_type: "email"),
             *create_list(:page, 3, answer_type: "name"),
           ])
  end
  let_it_be(:branch_route_form) do
    form = create(:form, :live, :ready_for_routing, submission_type: "s3", submission_format: %w[csv])
    create(:condition, :with_exit_page, routing_page_id: form.pages[0].id, check_page_id: form.pages[0].id, answer_value: "Option 1")
    create(:condition, routing_page_id: form.pages[1].id, check_page_id: form.pages[1].id, answer_value: "Option 1", goto_page_id: form.pages[3].id)
    create(:condition, routing_page_id: form.pages[2].id, check_page_id: form.pages[1].id, goto_page_id: form.pages[4].id)
    form.live_form_document.update!(content: form.reload.as_form_document(live_at: form.updated_at))
    form
  end
  let_it_be(:basic_route_form) do
    form = create(:form, :live, :ready_for_routing)
    create(:condition, routing_page_id: form.pages.first.id, check_page_id: form.pages.first.id, answer_value: "Option 1", skip_to_end: true)
    form.live_form_document.update!(content: form.reload.as_form_document(live_at: form.updated_at))
    form
  end
  let_it_be(:copied_form) do
    original_form = create(:form, :live, pages: [])
    form = create(:form, :live, copied_from_id: original_form.id, pages: [])
    form
  end
  let_it_be(:form_with_a_welsh_translation) do
    form = create(:form, :live, welsh_completed: true, pages: [])
    form
  end

  before do
    forms.each do |form|
      GroupForm.create!(form: form, group: group)
    end
  end

  describe "#report" do
    it "returns the feature report" do
      report = described_class.new(form_documents).report
      expect(report).to eq({
        total_forms: 6,
        copied_forms: 1,
        forms_with_payment: 1,
        forms_with_routing: 2,
        forms_with_branch_routing: 1,
        forms_with_add_another_answer: 1,
        forms_with_csv_submission_email_attachments: 2,
        forms_with_json_submission_email_attachments: 1,
        forms_with_daily_submission_csv: 1,
        forms_with_weekly_submission_csv: 1,
        forms_with_s3_submissions: 1,
        forms_with_answer_type: {
          "address" => 1,
          "date" => 1,
          "email" => 2,
          "name" => 2,
          "national_insurance_number" => 1,
          "number" => 1,
          "phone_number" => 1,
          "selection" => 3,
          "text" => 1,
        },
        steps_with_answer_type: {
          "address" => 1,
          "date" => 1,
          "email" => 2,
          "name" => 4,
          "national_insurance_number" => 1,
          "number" => 1,
          "phone_number" => 1,
          "selection" => 11,
          "text" => 1,
        },
        forms_with_exit_pages: 1,
        forms_with_welsh_translation: 1,
        forms_with_copy_of_answers_enabled: 1,
      })
    end
  end

  describe "#questions" do
    it "returns all questions in all forms given" do
      questions = described_class.new(form_documents).questions
      expect(questions.length).to eq 23
    end

    it "returns details needed to render report" do
      questions = described_class.new(form_documents).questions
      expect(questions).to all match(
        a_hash_including(
          "form" => a_hash_including(
            "form_id" => an_instance_of(Integer),
            "content" => a_hash_including(
              "name" => a_kind_of(String),
            ),
          ),
          "data" => a_hash_including(
            "question_text" => a_kind_of(String),
          ),
        ),
      )
    end

    it "includes a reference to the form document" do
      questions = described_class.new(form_documents).questions_with_answer_type("text")
      expect(questions).to all include(
        "form" => a_hash_including(
          "form_id",
          "content" => a_hash_including(
            "name",
          ),
        ),
      )
    end
  end

  describe "#questions_with_answer_type" do
    it "returns details needed to render report" do
      questions = described_class.new(form_documents).questions_with_answer_type("email")
      expect(questions.length).to eq 2
      expect(questions).to match [
        a_hash_including(
          "form" => a_hash_including(
            "form_id" => form_with_all_answer_types.id,
            "content" => a_hash_including(
              "name" => form_with_all_answer_types.name,
            ),
          ),
          "data" => a_hash_including(
            "question_text" => form_with_all_answer_types.pages[2].question_text,
          ),
        ),
        a_hash_including(
          "form" => a_hash_including(
            "form_id" => form_with_a_few_answer_types.id,
            "content" => a_hash_including(
              "name" => form_with_a_few_answer_types.name,
            ),
          ),
          "data" => a_hash_including(
            "question_text" => form_with_a_few_answer_types.pages[0].question_text,
          ),
        ),
      ]
    end

    it "returns questions with the given answer type" do
      questions = described_class.new(form_documents).questions_with_answer_type("name")
      expect(questions.length).to eq 4
      expect(questions).to all match(
        a_hash_including(
          "data" => a_hash_including(
            "answer_type" => "name",
          ),
        ),
      )
    end

    it "includes a reference to the form document" do
      questions = described_class.new(form_documents).questions_with_answer_type("text")
      expect(questions).to all include(
        "form" => a_hash_including(
          "form_id",
          "content" => a_hash_including(
            "name",
          ),
        ),
      )
    end
  end

  describe "#questions_with_add_another_answer" do
    it "returns details needed to render report" do
      questions = described_class.new(form_documents).questions_with_add_another_answer
      expect(questions).to contain_exactly(
        a_hash_including(
          "form" => a_hash_including(
            "form_id" => form_with_all_answer_types.id,
            "content" => a_hash_including(
              "name" => form_with_all_answer_types.name,
            ),
          ),
          "data" => a_hash_including(
            "question_text" => form_with_all_answer_types.pages[0].question_text,
          ),
        ),
        a_hash_including(
          "form" => a_hash_including(
            "form_id" => form_with_all_answer_types.id,
            "content" => a_hash_including(
              "name" => form_with_all_answer_types.name,
            ),
          ),
          "data" => a_hash_including(
            "question_text" => form_with_all_answer_types.pages[8].question_text,
          ),
        ),
      )
    end

    it "returns questions with add another answer" do
      questions = described_class.new(form_documents).questions_with_add_another_answer
      expect(questions).to all match(
        a_hash_including(
          "data" => a_hash_including(
            "is_repeatable" => true,
          ),
        ),
      )
    end

    it "includes a reference to the form document" do
      questions = described_class.new(form_documents).questions_with_answer_type("text")
      expect(questions).to all include(
        "form" => a_hash_including(
          "form_id",
          "content" => a_hash_including(
            "name",
          ),
        ),
      )
    end
  end

  describe "selection questions methods" do
    let(:page_with_autocomplete) { build(:page, :selection_with_autocomplete) }
    let(:page_with_radios) { build(:page, :selection_with_radios) }
    let(:page_with_checkboxes) { build(:page, :selection_with_checkboxes) }
    let(:not_selection_question) { build :page, answer_type: "name" }
    let(:form) { create(:form, :live, pages: [page_with_checkboxes, page_with_radios, page_with_autocomplete, not_selection_question]) }
    let(:forms) { [form] }

    describe "#selection_questions_with_autocomplete" do
      it "returns question with autocomplete" do
        questions = described_class.new(form_documents).selection_questions_with_autocomplete
        expect(questions.length).to be(1)
        expect(questions.first["data"]["question_text"]).to eq(page_with_autocomplete.question_text)
        expect(questions.first["form"]["form_id"]).to eq(form.id)
      end
    end

    describe "#selection_questions_with_radios" do
      it "returns question with radios" do
        questions = described_class.new(form_documents).selection_questions_with_radios
        expect(questions.length).to be(1)
        expect(questions.first["data"]["question_text"]).to eq(page_with_radios.question_text)
        expect(questions.first["form"]["form_id"]).to eq(form.id)
      end
    end

    describe "#selection_questions_with_checkboxes" do
      it "returns question with checkboxes" do
        questions = described_class.new(form_documents).selection_questions_with_checkboxes
        expect(questions.length).to be(1)
        expect(questions.first["data"]["question_text"]).to eq(page_with_checkboxes.question_text)
        expect(questions.first["form"]["form_id"]).to eq(form.id)
      end

      # This ensures there is backwards compatibility for existing questions as we previously set "only_one_option" to
      # "0" rather than "false"
      context "when question has only_one_option value '0'" do
        let(:page_with_checkboxes) do
          create(:page,
                 answer_type: "selection",
                 answer_settings: {
                   only_one_option: "0",
                   selection_options: [{ name: "Option 1" }, { name: "Option 2" }],
                 })
        end

        it "returns question with checkboxes" do
          questions = described_class.new(form_documents).selection_questions_with_checkboxes
          expect(questions.length).to be(1)
          expect(questions.first["data"]["question_text"]).to eq(page_with_checkboxes.question_text)
        end
      end
    end
  end

  describe "#selection_questions_with_none_of_the_above" do
    it "returns selection questions that include none of the above" do
      form = create(:form, :live, pages: [
        create(:page, :with_selection_settings, is_optional: true),
        create(:page, :with_selection_settings, is_optional: false),
      ])
      form_document = form.live_form_document.as_json

      questions = described_class.new([form_document]).selection_questions_with_none_of_the_above
      expect(questions.length).to eq 1
      expect(questions.first["data"]["question_text"]).to eq(form.pages[0].question_text)
    end
  end

  describe "#forms_with_branch_routes" do
    it "returns details needed to render report" do
      forms = described_class.new(form_documents).forms_with_branch_routes
      expect(forms).to match [
        a_hash_including(
          "form_id" => branch_route_form.id,
          "content" => a_hash_including(
            "name" => branch_route_form.name,
          ),
          "metadata" => {
            "number_of_routes" => 3,
            "number_of_branch_routes" => 1,
          },
        ),
      ]
    end

    it "returns forms with branch routes" do
      forms = described_class.new(form_documents).forms_with_branch_routes
      expect(forms).to match [
        a_hash_including(
          "form_id" => branch_route_form.id,
          "content" => a_hash_including(
            "name" => branch_route_form.name,
          ),
        ),
      ]
    end

    it "includes counts of routes" do
      forms = described_class.new(form_documents).forms_with_branch_routes
      expect(forms).to all include(
        "metadata" => a_hash_including(
          "number_of_routes" => an_instance_of(Integer),
          "number_of_branch_routes" => an_instance_of(Integer),
        ),
      )
    end
  end

  describe "#forms_with_payments" do
    it "returns live forms with payments" do
      forms = described_class.new(form_documents).forms_with_payments
      expect(forms).to match [
        a_hash_including(
          "form_id" => form_with_all_answer_types.id,
          "content" => a_hash_including(
            "name" => form_with_all_answer_types.name,
          ),
        ),
      ]
    end
  end

  describe "#forms_with_exit_pages" do
    it "returns live forms with payments" do
      forms = described_class.new(form_documents).forms_with_exit_pages
      expect(forms).to match [
        a_hash_including(
          "form_id" => branch_route_form.id,
          "content" => a_hash_including(
            "name",
          ),
        ),
      ]
    end
  end

  describe "#forms_with_csv_submission_email_attachments" do
    it "returns live forms with csv enabled" do
      forms = described_class.new(form_documents).forms_with_csv_submission_email_attachments
      expect(forms.length).to eq 2
      expect(forms).to match [
        a_hash_including(
          "form_id" => form_with_all_answer_types.id,
          "content" => a_hash_including(
            "name" => form_with_all_answer_types.name,
          ),
        ),
        a_hash_including(
          "form_id" => form_with_a_few_answer_types.id,
          "content" => a_hash_including(
            "name" => form_with_a_few_answer_types.name,
          ),
        ),
      ]
    end
  end

  describe "#forms_with_json_submission_email_attachments" do
    it "returns live forms with json enabled" do
      forms = described_class.new(form_documents).forms_with_json_submission_email_attachments
      expect(forms.length).to eq 1
      expect(forms).to match [
        a_hash_including(
          "form_id" => form_with_a_few_answer_types.id,
          "content" => a_hash_including(
            "name" => form_with_a_few_answer_types.name,
          ),
        ),
      ]
    end
  end

  describe "#forms_with_daily_submission_csv" do
    it "returns live forms with daily submission csv enabled" do
      forms = described_class.new(form_documents).forms_with_daily_submission_csv
      expect(forms.length).to eq 1
      expect(forms).to match [
        a_hash_including(
          "form_id" => form_with_a_few_answer_types.id,
          "content" => a_hash_including(
            "name" => form_with_a_few_answer_types.name,
          ),
        ),
      ]
    end
  end

  describe "#forms_with_weekly_submission_csv" do
    it "returns live forms with weekly submission csv enabled" do
      forms = described_class.new(form_documents).forms_with_weekly_submission_csv
      expect(forms.length).to eq 1
      expect(forms).to match [
        a_hash_including(
          "form_id" => form_with_a_few_answer_types.id,
          "content" => a_hash_including(
            "name" => form_with_a_few_answer_types.name,
          ),
        ),
      ]
    end
  end

  describe "#forms_with_s3_submissions" do
    it "returns live forms with json enabled" do
      forms = described_class.new(form_documents).forms_with_s3_submissions
      expect(forms.length).to eq 1
      expect(forms).to match [
        a_hash_including(
          "form_id" => branch_route_form.id,
          "content" => a_hash_including(
            "name" => branch_route_form.name,
          ),
        ),
      ]
    end
  end

  describe "#forms_that_are_copies" do
    it "returns forms that are copies" do
      forms = described_class.new(form_documents).forms_that_are_copies
      expect(forms.length).to eq 1
      expect(forms).to match [
        a_hash_including(
          "form_id" => copied_form.id,
          "content" => a_hash_including(
            "name" => copied_form.name,
            "copied_from_id" => copied_form.copied_from_id,
          ),
        ),
      ]
    end
  end

  describe "#forms_with_welsh_translation" do
    it "returns live forms with welsh translation" do
      forms = described_class.new(form_documents).forms_with_welsh_translation
      expect(forms.length).to eq 1
      expect(forms).to match [
        a_hash_including(
          "form_id" => form_with_a_welsh_translation.id,
          "content" => a_hash_including(
            "name" => form_with_a_welsh_translation.name,
          ),
        ),
      ]
    end
  end

  describe "#forms_with_copy_of_answers_enabled" do
    it "returns live forms with copy of answers enabled" do
      forms = described_class.new(form_documents).forms_with_copy_of_answers_enabled
      expect(forms.length).to eq 1
      expect(forms).to match [
        a_hash_including(
          "form_id" => form_with_all_answer_types.id,
          "content" => a_hash_including(
            "name" => form_with_all_answer_types.name,
          ),
        ),
      ]
    end
  end
end
