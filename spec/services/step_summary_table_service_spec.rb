require "rails_helper"

describe StepSummaryTableService do
  subject(:step_summary_table_service) do
    described_class.new(step: form_document_step, steps: form_document_steps, welsh_steps: welsh_form_document_steps)
  end

  let(:form) { create :form, :with_welsh_translation, :live, id: 1, pages: }
  let(:pages) { [page] }
  let(:page) { create(:page) }

  let(:form_document_content) { FormDocument::Content.from_form_document(form.live_form_document) }
  let(:welsh_form_document_content) { FormDocument::Content.from_form_document(form.live_welsh_form_document) }
  let(:form_document_steps) { form_document_content.steps }
  let(:welsh_form_document_steps) { welsh_form_document.steps }
  let(:form_document_step) { FormDocument::Step.new(page.as_form_document_step(nil)) }
  let(:welsh_form_document) { FormDocument::Content.from_form_document(form.live_welsh_form_document) }

  before do
    form.set_task_status_service(TaskStatusService.new(form:))
  end

  def create_form(attributes = {})
    default_attributes = {
      id: 1,
      name: "Apply for a juggling licence",
      name_cy: "Apply for a juggling licence (Welsh)",
      what_happens_next_markdown: "English what happens next",
      what_happens_next_markdown_cy: "Welsh what happens next",
      declaration_markdown: "English declaration",
      declaration_markdown_cy: "Welsh declaration",
      support_email: "english-support@example.gov.uk",
      support_email_cy: "welsh-support@example.gov.uk",
      support_phone: "01234 987654",
      support_phone_cy: "01234 567891",
      support_url_cy: "https://www.gov.uk/welsh-support",
      support_url: "https://www.gov.uk/english-support",
      support_url_text_cy: "Welsh Support",
      support_url_text: "English Support",
      privacy_policy_url: "https://www.gov.uk/english-privacy",
      privacy_policy_url_cy: "https://www.gov.uk/welsh-privacy",
      payment_url: "https://www.gov.uk/english-payment",
      payment_url_cy: "https://www.gov.uk/payments/your-welsh-payment-link",
      welsh_completed: true,
      question_section_completed: true,
      declaration_section_completed: true,
      share_preview_completed: true,
      pages: [],
    }
    create(:form, :live, default_attributes.merge(attributes))
  end

  def create_page(attributes = {})
    default_attributes = {
      question_text: "Are you renewing a licence?",
      hint_text: "Choose 'Yes' if you already have a valid licence.",
      page_heading: "Licencing",
      guidance_markdown: "This part of the form concerns licencing.",
      question_text_cy: "Ydych chi'n adnewyddu trwydded?",
      hint_text_cy: "Dewiswch 'Ydw' os oes gennych drwydded ddilys eisoes.",
      page_heading_cy: "Trwyddedu",
      guidance_markdown_cy: "Mae'r rhan hon o'r ffurflen yn ymwneud â thrwyddedu.",
      form:,
    }
    create(:page, default_attributes.merge(attributes))
  end

  describe "#values_with_welsh_content" do
    context "when the page includes guidance markdown" do
      let(:page) do
        create(:page,
               question_text: "Are you renewing a licence?",
               question_text_cy: "Ydych chi'n adnewyddu trwydded?",
               page_heading: "Licencing",
               guidance_markdown: "This part of the form concerns licencing.",
               page_heading_cy: "Trwyddedu",
               guidance_markdown_cy: "Mae'r rhan hon o'r ffurflen yn ymwneud â thrwyddedu.")
      end

      it "includes a row for the page heading" do
        expect(step_summary_table_service.values_with_welsh_content).to include [I18n.t("step_summary_card.page_heading"), page.page_heading, page.page_heading_cy]
      end

      it "includes a formatted row for the guidance markdown" do
        expect(step_summary_table_service.values_with_welsh_content).to include [
          I18n.t("step_summary_card.guidance_markdown"),
          "<pre class=\"app-markdown-editor__markdown-example-block\">".html_safe + page.guidance_markdown + "</pre>".html_safe,
          "<pre class=\"app-markdown-editor__markdown-example-block\">".html_safe + page.guidance_markdown_cy + "</pre>".html_safe,
        ]
      end

      it "includes a row for the question text" do
        expect(step_summary_table_service.values_with_welsh_content).to include ["Question text", page.question_text, page.question_text_cy]
      end
    end

    context "when the page includes hint_text" do
      let(:page) do
        create(:page,
               question_text: "Are you renewing a licence?",
               question_text_cy: "Ydych chi'n adnewyddu trwydded?",
               hint_text: "Choose 'Yes' if you already have a valid licence.",
               hint_text_cy: "Dewiswch 'Ydw' os oes gennych drwydded ddilys eisoes.")
      end

      it "includes a row for the hint text" do
        expect(step_summary_table_service.values_with_welsh_content).to include [I18n.t("step_summary_card.hint_text"),
                                                                                 page.hint_text,
                                                                                 page.hint_text_cy]
      end
    end

    context "when the page is a selection question" do
      let(:page) do
        create(:page,
               question_text: "Are you renewing a licence?",
               question_text_cy: "Ydych chi'n adnewyddu trwydded?",
               answer_type: "selection",
               is_optional: true,
               answer_settings: {
                 "only_one_option" => "true",
                 "selection_options" => [{ name: "Yes", value: "Yes" }, { name: "No", value: "No" }],
               }.to_json,
               answer_settings_cy: {
                 "only_one_option" => "true",
                 "selection_options" => [{ name: "Ydy", value: "Yes" }, { name: "Nac ydy", value: "No" }],
               }.to_json)
      end

      it "includes a row for the selection options" do
        selection_list = "<p>#{I18n.t('page_settings_summary.selection.options_count', number_of_options: 3)}</p><ul class=\"govuk-list govuk-list--bullet\"><li>Yes</li><li>No</li><li>None of the above</li></ul>"
        selection_list_cy = "<p>#{I18n.t('page_settings_summary.selection.options_count', number_of_options: 3)}</p><ul class=\"govuk-list govuk-list--bullet\"><li>Ydy</li><li>Nac ydy</li><li>Dim un o’r uchod</li></ul>"
        expect(step_summary_table_service.values_with_welsh_content).to include [I18n.t("step_summary_card.options_title"), selection_list, selection_list_cy]
      end

      context "when there are more than 10 options" do
        let(:page) do
          create(:page,
                 question_text: "Are you renewing a licence?",
                 question_text_cy: "Ydych chi'n adnewyddu trwydded?",
                 answer_type: "selection",
                 answer_settings: {
                   "only_one_option" => "true",
                   "selection_options" => [
                     { name: "One", value: "One" },
                     { name: "Two", value: "Two" },
                     { name: "Three", value: "Three" },
                     { name: "Four", value: "Four" },
                     { name: "Five", value: "Five" },
                     { name: "Six", value: "Six" },
                     { name: "Seven", value: "Seven" },
                     { name: "Eight", value: "Eight" },
                     { name: "Nine", value: "Nine" },
                     { name: "Ten", value: "Ten" },
                     { name: "Eleven", value: "Eleven" },
                   ],
                 }.to_json,
                 answer_settings_cy: {
                   "only_one_option" => "true",
                   "selection_options" => [
                     { name: "Un", value: "One" },
                     { name: "Dau", value: "Two" },
                     { name: "Tri", value: "Three" },
                     { name: "Pedwar", value: "Four" },
                     { name: "Pum", value: "Five" },
                     { name: "Chwe", value: "Six" },
                     { name: "Saith", value: "Seven" },
                     { name: "Wyth", value: "Eight" },
                     { name: "Naw", value: "Nine" },
                     { name: "Deg", value: "Ten" },
                     { name: "Un ar ddeg", value: "Eleven" },
                   ],
                 }.to_json)
        end

        it "includes a row with the selection options in a details component" do
          selection_list = "<details class=\"govuk-details\"><summary class=\"govuk-details__summary\"><span class=\"govuk-details__summary-text\">Show 11 options</span></summary><div class=\"govuk-details__text\"><ul class=\"govuk-list govuk-list--bullet\"><li>One</li><li>Two</li><li>Three</li><li>Four</li><li>Five</li><li>Six</li><li>Seven</li><li>Eight</li><li>Nine</li><li>Ten</li><li>Eleven</li></ul></div></details>"
          selection_list_cy = "<details class=\"govuk-details\"><summary class=\"govuk-details__summary\"><span class=\"govuk-details__summary-text\">Show 11 options</span></summary><div class=\"govuk-details__text\"><ul class=\"govuk-list govuk-list--bullet\"><li>Un</li><li>Dau</li><li>Tri</li><li>Pedwar</li><li>Pum</li><li>Chwe</li><li>Saith</li><li>Wyth</li><li>Naw</li><li>Deg</li><li>Un ar ddeg</li></ul></div></details>"
          expect(step_summary_table_service.values_with_welsh_content).to include [I18n.t("step_summary_card.options_title"), selection_list, selection_list_cy]
        end
      end

      context "when there is custom 'None of the above' text" do
        let(:page) do
          create(:page,
                 is_optional: true,
                 question_text: "Are you renewing a licence?",
                 question_text_cy: "Ydych chi'n adnewyddu trwydded?",
                 answer_type: "selection",
                 answer_settings: {
                   "only_one_option" => "true",
                   "selection_options" => [
                     {
                       name: "Yes",
                       value: "Yes",
                     },
                     {
                       name: "No",
                       value: "No",
                     },
                   ],
                   none_of_the_above_question: { question_text: "Enter something" },
                 }.to_json,
                 answer_settings_cy: {
                   "only_one_option" => "true",
                   "selection_options" => [
                     {
                       name: "Ydy",
                       value: "Yes",
                     },
                     {
                       name: "Nac ydy",
                       value: "No",
                     },
                   ],
                   none_of_the_above_question: { question_text: "Rhowch rywbeth i mewn" },
                 }.to_json)
        end

        it "includes a row with the none of the above text" do
          expect(step_summary_table_service.values_with_welsh_content).to include [I18n.t("step_summary_card.none_of_the_above_question_title"), page.answer_settings[:none_of_the_above_question][:question_text], page.answer_settings_cy[:none_of_the_above_question][:question_text]]
        end
      end
    end
  end

  describe "#values_with_welsh_content2", :feature_multiple_branches do
    let(:form) do
      create :form,
             :with_welsh_translation,
             :ready_for_live,
             id: 1,
             name: "Apply for a juggling licence",
             name_cy: "Apply for a juggling licence (Welsh)",
             what_happens_next_markdown: "English what happens next",
             what_happens_next_markdown_cy: "Welsh what happens next",
             declaration_markdown: "English declaration",
             declaration_markdown_cy: "Welsh declaration",
             support_email: "english-support@example.gov.uk",
             support_email_cy: "welsh-support@example.gov.uk",
             support_phone: "01234 987654",
             support_phone_cy: "01234 567891",
             support_url_cy: "https://www.gov.uk/welsh-support",
             support_url: "https://www.gov.uk/english-support",
             support_url_text_cy: "Welsh Support",
             support_url_text: "English Support",
             privacy_policy_url: "https://www.gov.uk/english-privacy",
             privacy_policy_url_cy: "https://www.gov.uk/welsh-privacy",
             payment_url: "https://www.gov.uk/english-payment",
             payment_url_cy: "https://www.gov.uk/payments/your-welsh-payment-link",
             welsh_completed: true,
             pages: [
               create(
                 :page,
                 question_text: "Question",
                 question_text_cy: "Question (Welsh)",
               ),
               create(
                 :page,
                 :with_selection_settings,
                 question_text: "Branch question",
                 question_text_cy: "Branch question (Welsh)",
                 is_optional: true,
                 answer_settings: DataStruct.new(
                   only_one_option: "true",
                   selection_options: [
                     {
                       name: "First branch",
                       value: "First branch",
                     },
                     {
                       name: "Second branch",
                       value: "Second branch",
                     },
                     {
                       name: "Also second branch",
                       value: "Also second branch",
                     },
                     {
                       name: "Skip the branches",
                       value: "Skip the branches",
                     },
                   ],
                 ),
                 answer_settings_cy: DataStruct.new(
                   only_one_option: "true",
                   selection_options: [
                     {
                       name: "First branch (Welsh)",
                       value: "First branch",
                     },
                     {
                       name: "Second branch (Welsh)",
                       value: "Second branch",
                     },
                     {
                       name: "Also second branch (Welsh)",
                       value: "Also second branch",
                     },
                     {
                       name: "Skip the branches (Welsh)",
                       value: "Skip the branches",
                     },
                   ],
                 ),
               ),
               create(
                 :page,
                 question_text: "Question in branch 1",
                 question_text_cy: "Question in branch 1 (Welsh)",
               ),
               create(
                 :page,
                 question_text: "Question at the end of branch 1",
                 question_text_cy: "Question at the end of branch 1 (Welsh)",
               ),
               create(
                 :page,
                 question_text: "Question at the start of branch 2",
                 question_text_cy: "Question at the start of branch 2 (Welsh)",
               ),
               create(
                 :page,
                 question_text: "Question in branch 2",
                 question_text_cy: "Question in branch 2 (Welsh)",
               ),
               create(
                 :page,
                 question_text: "Question at the end of branch 2",
                 question_text_cy: "Question at the end of branch 2 (Welsh)",
               ),
               create(
                 :page,
                 question_text: "Question",
                 question_text_cy: "Question (Welsh)",
               ),
             ]
    end

    let(:pages) do
      form.pages
    end

    let(:pages_with_routing) do
      # Create conditions separately
      create(
        :condition,
        answer_value: "Second branch",
        goto_page_id: pages[4].id,
        routing_page_id: pages[1].id,
      )

      create(
        :condition,
        answer_value: "Also second branch",
        goto_page_id: pages[4].id,
        routing_page_id: pages[1].id,
      )

      create(
        :condition,
        answer_value: "Also second branch",
        goto_page_id: pages[7].id,
        routing_page_id: pages[1].id,
      )

      create(
        :condition,
        answer_value: "none_of_the_above",
        routing_page_id: pages[1].id,
        skip_to_end: true,
      )

      create(
        :condition,
        routing_page_id: pages[3].id,
        goto_page_id: pages[7].id,
      )

      create(
        :condition,
        routing_page_id: pages[6].id,
        skip_to_end: true,
      )

      pages.each(&:reload)
      form.save_draft!
      form.make_live!
      pages
    end

    before do
      pages_with_routing
      form.reload
      pages.reload
    end

    context "when the page is a selection page with routing" do
      let(:page) { pages_with_routing[1] }

      it "includes a row for the routes" do
        expect(step_summary_table_service.values_with_welsh_content2).to include([
          "Routes",
          "<p>Go to 5, ‘Question at the start of branch 2’ if the answer is:</p><ul class=\"govuk-list govuk-list--bullet govuk-!-static-margin-bottom-4\"><li>‘Second branch’</li><li>‘Also second branch’</li></ul>"\
          "<p>Go to 8, ‘Question’ if the answer is:</p><ul class=\"govuk-list govuk-list--bullet govuk-!-static-margin-bottom-4\"><li>‘Also second branch’</li></ul>"\
          "<p>Go to the end of the form if the answer is:</p><ul class=\"govuk-list govuk-list--bullet govuk-!-static-margin-bottom-4\"><li>‘None of the above’</li></ul>",
          "<p>Go to 5, ‘Question at the start of branch 2 (Welsh)’ if the answer is:</p><ul class=\"govuk-list govuk-list--bullet govuk-!-static-margin-bottom-4\"><li>‘Second branch (Welsh)’</li><li>‘Also second branch (Welsh)’</li></ul>"\
          "<p>Go to 8, ‘Question (Welsh)’ if the answer is:</p><ul class=\"govuk-list govuk-list--bullet govuk-!-static-margin-bottom-4\"><li>‘Also second branch (Welsh)’</li></ul>"\
          "<p>Go to the end of the form if the answer is:</p><ul class=\"govuk-list govuk-list--bullet govuk-!-static-margin-bottom-4\"><li>‘Dim un o’r uchod’</li></ul>",
        ])
      end
    end

    context "when the page unconditionally skips to another page" do
      let(:page) { pages_with_routing[3] }

      it "includes a row for the routes" do
        expect(step_summary_table_service.values_with_welsh_content2).to include([
          "Route",
          "Go to 8, ‘Question’",
          "Go to 8, ‘Question (Welsh)’",
        ])
      end
    end

    context "when the page unconditionally skips to the end" do
      let(:page) { pages_with_routing[6] }

      it "includes a row for the routes" do
        expect(step_summary_table_service.values_with_welsh_content2).to include([
          "Route",
          "Go to the end of the form",
          "Go to the end of the form",
        ])
      end
    end
  end

  describe "#untranslated_content" do
    let(:page) do
      create(:page,
             question_text: "Are you renewing a licence?",
             question_text_cy: "Ydych chi'n adnewyddu trwydded?",
             answer_type:,
             answer_settings:,
             answer_settings_cy: answer_settings)
    end

    context "when the page is a text question" do
      let(:answer_type) { "text" }

      context "when the page is configured as a single line of text" do
        let(:answer_settings) { { input_type: "single_line" } }

        it "returns data for the Answer Type details component" do
          expect(step_summary_table_service.untranslated_content).to eq({
            summary: I18n.t("step_summary_card.answer_type"),
            text: I18n.t("helpers.label.page.text_settings_options.names.single_line"),
          })
        end
      end

      context "when the page is configured as long text" do
        let(:answer_settings) { { input_type: "long_text" } }

        it "returns data for the Answer Type details component" do
          expect(step_summary_table_service.untranslated_content).to eq({
            summary: I18n.t("step_summary_card.answer_type"),
            text: I18n.t("helpers.label.page.text_settings_options.names.long_text"),
          })
        end
      end
    end

    context "when the page is a date question" do
      let(:answer_type) { "date" }

      context "when the page is configured as a generic date" do
        let(:answer_settings) { { input_type: "other_date" } }

        it "returns data for the Answer Type details component" do
          expect(step_summary_table_service.untranslated_content).to eq({
            summary: I18n.t("step_summary_card.answer_type"),
            text: I18n.t("step_summary_card.date_type.other_date"),
          })
        end
      end

      context "when the page is configured as a date of birth" do
        let(:answer_settings) { { input_type: "date_of_birth" } }

        it "returns data for the Answer Type details component" do
          expect(step_summary_table_service.untranslated_content).to eq({
            summary: I18n.t("step_summary_card.answer_type"),
            text: I18n.t("step_summary_card.date_type.date_of_birth"),
          })
        end
      end
    end

    context "when the page is a address question" do
      let(:answer_type) { "address" }

      context "when the page is configured as a UK address" do
        let(:answer_settings) do
          {
            input_type: {
              uk_address: "true",
              international_address: "false",
            },
          }
        end

        it "returns data for the Answer Type details component" do
          expect(step_summary_table_service.untranslated_content).to eq({
            summary: I18n.t("step_summary_card.answer_type"),
            text: I18n.t("helpers.label.page.address_settings_options.names.uk_addresses"),
          })
        end
      end

      context "when the page is configured as an international address" do
        let(:answer_settings) do
          {
            input_type: {
              uk_address: "false",
              international_address: "true",
            },
          }
        end

        it "returns data for the Answer Type details component" do
          expect(step_summary_table_service.untranslated_content).to eq({
            summary: I18n.t("step_summary_card.answer_type"),
            text: I18n.t("helpers.label.page.address_settings_options.names.international_addresses"),
          })
        end
      end

      context "when the page is configured as a UK or international address" do
        let(:answer_settings) do
          {
            input_type: {
              uk_address: "true",
              international_address: "true",
            },
          }
        end

        it "returns data for the Answer Type details component" do
          expect(step_summary_table_service.untranslated_content).to eq({
            summary: I18n.t("step_summary_card.answer_type"),
            text: I18n.t("helpers.label.page.address_settings_options.names.uk_and_international_addresses"),
          })
        end
      end
    end

    context "when the page is a name question" do
      let(:answer_type) { "name" }

      context "when the page is configured as a full name" do
        let(:answer_settings) { { input_type: "full_name", title_needed: "false" } }

        it "returns data for the Answer Type details component" do
          expect(step_summary_table_service.untranslated_content).to eq({
            summary: I18n.t("step_summary_card.answer_type"),
            text: "<ul class=\"govuk-list\"><li>#{I18n.t('helpers.label.page.answer_type_options.names.name')}</li><li>#{I18n.t('helpers.label.page.name_settings_options.names.full_name')}</li><li>#{I18n.t('step_summary_card.name_type.title_not_selected')}</li></ul>",
          })
        end
      end

      context "when the page is configured as a first and last name" do
        let(:answer_settings) { { input_type: "first_and_last_name", title_needed: "false" } }

        it "returns data for the Answer Type details component" do
          expect(step_summary_table_service.untranslated_content).to eq({
            summary: I18n.t("step_summary_card.answer_type"),
            text: "<ul class=\"govuk-list\"><li>#{I18n.t('helpers.label.page.answer_type_options.names.name')}</li><li>#{I18n.t('helpers.label.page.name_settings_options.names.first_and_last_name')}</li><li>#{I18n.t('step_summary_card.name_type.title_not_selected')}</li></ul>",
          })
        end
      end

      context "when the page is configured as a first, last, and middle names" do
        let(:answer_settings) { { input_type: "first_middle_and_last_name", title_needed: "false" } }

        it "returns data for the Answer Type details component" do
          expect(step_summary_table_service.untranslated_content).to eq({
            summary: I18n.t("step_summary_card.answer_type"),
            text: "<ul class=\"govuk-list\"><li>#{I18n.t('helpers.label.page.answer_type_options.names.name')}</li><li>#{I18n.t('helpers.label.page.name_settings_options.names.first_middle_and_last_name')}</li><li>#{I18n.t('step_summary_card.name_type.title_not_selected')}</li></ul>",
          })
        end
      end

      context "when the page is configured to ask for a title" do
        let(:answer_settings) { { input_type: "full_name", title_needed: "true" } }

        it "returns data for the Answer Type details component" do
          expect(step_summary_table_service.untranslated_content).to eq({
            summary: I18n.t("step_summary_card.answer_type"),
            text: "<ul class=\"govuk-list\"><li>#{I18n.t('helpers.label.page.answer_type_options.names.name')}</li><li>#{I18n.t('helpers.label.page.name_settings_options.names.full_name')}</li><li>#{I18n.t('step_summary_card.name_type.title_selected')}</li></ul>",
          })
        end
      end
    end

    Page::ANSWER_TYPES_WITHOUT_SETTINGS.each do |answer_type_without_settings|
      context "when the page has answer type #{answer_type_without_settings}" do
        let(:answer_type) { answer_type_without_settings }
        let(:answer_settings) { nil }

        it "returns data for the Answer Type details component" do
          expect(step_summary_table_service.untranslated_content).to eq({
            summary: I18n.t("step_summary_card.answer_type"),
            text: I18n.t("helpers.label.page.answer_type_options.names.#{answer_type_without_settings}"),
          })
        end
      end
    end
  end

  describe "#route_content" do
    context "when the form has routing conditions" do
      let(:form) do
        create :form,
               :with_welsh_translation,
               :ready_for_live,
               id: 1,
               name: "Apply for a juggling licence",
               name_cy: "Apply for a juggling licence (Welsh)",
               what_happens_next_markdown: "English what happens next",
               what_happens_next_markdown_cy: "Welsh what happens next",
               declaration_markdown: "English declaration",
               declaration_markdown_cy: "Welsh declaration",
               support_email: "english-support@example.gov.uk",
               support_email_cy: "welsh-support@example.gov.uk",
               support_phone: "01234 987654",
               support_phone_cy: "01234 567891",
               support_url_cy: "https://www.gov.uk/welsh-support",
               support_url: "https://www.gov.uk/english-support",
               support_url_text_cy: "Welsh Support",
               support_url_text: "English Support",
               privacy_policy_url: "https://www.gov.uk/english-privacy",
               privacy_policy_url_cy: "https://www.gov.uk/welsh-privacy",
               payment_url: "https://www.gov.uk/english-payment",
               payment_url_cy: "https://www.gov.uk/payments/your-welsh-payment-link",
               welsh_completed: true,
               pages: [
                 create(
                   :page,
                   question_text: "Question",
                   question_text_cy: "Question (Welsh)",
                 ),
                 create(
                   :page,
                   :with_selection_settings,
                   question_text: "Branch question (start of a route)",
                   question_text_cy: "Branch question (start of a route) (Welsh)",
                   answer_settings: DataStruct.new(
                     only_one_option: "true",
                     selection_options: [
                       {
                         name: "First branch",
                         value: "First branch",
                       },
                       {
                         name: "Second branch",
                         value: "Second branch",
                       },
                     ],
                   ),
                   answer_settings_cy: DataStruct.new(
                     only_one_option: "true",
                     selection_options: [
                       {
                         name: "First branch (Welsh)",
                         value: "First branch",
                       },
                       {
                         name: "Second branch (Welsh)",
                         value: "Second branch",
                       },
                     ],
                   ),
                 ),
                 create(
                   :page,
                   question_text: "Question in branch 1",
                   question_text_cy: "Question in branch 1 (Welsh)",
                 ),
                 create(
                   :page,
                   question_text: "Question at the end of branch 1 (start of a secondary skip)",
                   question_text_cy: "Question at the end of branch 1 (start of a secondary skip) (Welsh)",
                 ),
                 create(
                   :page,
                   question_text: "Question at the start of branch 2 (end of a route)",
                   question_text_cy: "Question at the start of branch 2 (end of a route) (Welsh)",
                 ),
                 create(
                   :page,
                   question_text: "Question in branch 2",
                   question_text_cy: "Question in branch 2 (Welsh)",
                 ),
                 create(
                   :page,
                   question_text: "Question at the end of branch 2",
                   question_text_cy: "Question at the end of branch 2 (Welsh)",
                 ),
                 create(
                   :page,
                   question_text: "Question after a branch route (end of a secondary skip)",
                   question_text_cy: "Question after a branch route (end of a secondary skip) (Welsh)",
                 ),
                 create(
                   :page,
                   question_text: "Question",
                   question_text_cy: "Question (Welsh)",
                 ),
                 create(
                   :page,
                   :with_selection_settings,
                   question_text: "Skip question",
                   question_text_cy: "Skip question (Welsh)",
                   answer_settings: DataStruct.new(only_one_option: "true", selection_options: [{ name: "Skip", value: "Skip" }, { name: "Don't skip", value: "Don't skip" }]),
                   answer_settings_cy: DataStruct.new(only_one_option: "true", selection_options: [{ name: "Skip (Welsh)", value: "Skip" }, { name: "Don't skip (Welsh)", value: "Don't skip" }]),
                 ),
                 create(
                   :page,
                   :with_selection_settings,
                   question_text: "Question to be skipped",
                   question_text_cy: "Question to be skipped (Welsh)",
                   answer_settings: DataStruct.new(only_one_option: "true", selection_options: [{ name: "Skip to end", value: "Skip to end" }, { name: "Don't skip", value: "Don't skip" }]),
                   answer_settings_cy: DataStruct.new(only_one_option: "true", selection_options: [{ name: "Skip to end (Welsh)", value: "Skip to end" }, { name: "Don't skip (Welsh)", value: "Don't skip" }]),
                 ),
                 create(
                   :page,
                   question_text: "Question",
                   question_text_cy: "Question (Welsh)",
                 ),
                 create(
                   :page,
                   :with_selection_settings,
                   question_text: "Exit page question",
                   question_text_cy: "Exit page question (Welsh)",
                   answer_settings: DataStruct.new(
                     only_one_option: "true",
                     selection_options: [
                       {
                         name: "Exit",
                         value: "Exit",
                       },
                       {
                         name: "Don't exit",
                         value: "Don't exit",
                       },
                     ],
                   ),
                   answer_settings_cy: DataStruct.new(
                     only_one_option: "true",
                     selection_options: [
                       {
                         name: "Exit (Welsh)",
                         value: "Exit",
                       },
                       {
                         name: "Don't exit (Welsh)",
                         value: "Don't exit",
                       },
                     ],
                   ),
                 ),
                 create(
                   :page,
                   :with_selection_settings,
                   question_text: "Question with none of the above",
                   question_text_cy: "Question with none of the above (Welsh)",
                   is_optional: true,
                   answer_settings: DataStruct.new(only_one_option: "true", selection_options: [{ name: "Option 1", value: "Option 1" }, { name: "Option 2", value: "Option 2" }]),
                   answer_settings_cy: DataStruct.new(only_one_option: "true", selection_options: [{ name: "Option 1 (Welsh)", value: "Option 1" }, { name: "Option 2 (Welsh)", value: "Option 2" }]),
                 ),
                 create(
                   :page,
                   question_text: "Question",
                   question_text_cy: "Question (Welsh)",
                 ),
               ]
      end

      let(:pages) do
        form.pages
      end

      let(:pages_with_routing) do
        # Create conditions separately
        create(
          :condition,
          answer_value: "Second branch",
          check_page_id: pages[1].id,
          goto_page_id: pages[4].id,
          routing_page_id: pages[1].id,
          exit_page_heading: nil,
          exit_page_markdown: nil,
        )

        create(
          :condition,
          answer_value: nil,
          check_page_id: pages[1].id,
          goto_page_id: pages[7].id,
          routing_page_id: pages[3].id,
          exit_page_heading: nil,
          exit_page_markdown: nil,
        )

        create(
          :condition,
          answer_value: "Skip",
          check_page_id: pages[9].id,
          goto_page_id: pages[11].id,
          routing_page_id: pages[9].id,
          exit_page_heading: nil,
          exit_page_markdown: nil,
        )

        create(
          :condition,
          answer_value: "Skip to end",
          check_page_id: pages[10].id,
          goto_page_id: nil,
          routing_page_id: pages[10].id,
          exit_page_heading: nil,
          exit_page_markdown: nil,
          skip_to_end: true,
        )

        create(
          :condition,
          answer_value: "Exit",
          check_page_id: pages[12].id,
          goto_page_id: nil,
          routing_page_id: pages[12].id,
          exit_page_heading: "Exit page heading",
          exit_page_heading_cy: "Exit page heading (Welsh)",
          exit_page_markdown: "Exit page markdown",
          exit_page_markdown_cy: "Exit page markdown (Welsh)",
        )

        create(
          :condition,
          answer_value: "none_of_the_above",
          check_page_id: pages[13].id,
          routing_page_id: pages[13].id,
          skip_to_end: true,
        )

        pages.each(&:reload)
        form.save_draft!
        form.make_live!
        pages
      end

      let(:branch_route_1) do
        page_with_skip_and_secondary_skip.routing_conditions.first
      end

      let(:branch_any_other_answer_route) do
        start_of_a_secondary_skip.routing_conditions.first
      end

      let(:skip_route) do
        page_with_skip_route.routing_conditions.first
      end

      let(:page_with_no_routes) do
        pages_with_routing[0]
      end

      let(:page_with_skip_and_secondary_skip) do
        pages_with_routing[1]
      end

      let(:start_of_a_secondary_skip) do
        pages_with_routing[3]
      end

      let(:end_of_a_secondary_skip) do
        pages_with_routing[7]
      end

      let(:page_with_skip_route) do
        pages_with_routing[9]
      end

      let(:page_with_skip_to_end) do
        pages_with_routing[10]
      end

      let(:page_with_exit_page) do
        pages_with_routing[12]
      end

      let(:page_with_none_of_the_above) do
        pages_with_routing[13]
      end

      let(:exit_page) do
        page_with_exit_page.routing_conditions.first
      end

      context "when a page has no routes" do
        let(:page) { page_with_no_routes }

        it "returns an empty array" do
          expect(step_summary_table_service.route_content).to eq []
        end
      end

      context "when a page has a skip route" do
        let(:page) { page_with_skip_route }

        it "returns an array containing the skip condition data" do
          expect(step_summary_table_service.route_content).to eq [{ answer_value: "Skip",
                                                                    answer_value_cy: "Skip (Welsh)",
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
      end

      context "when a page has a skip route and a secondary skip route" do
        let(:page) { page_with_skip_and_secondary_skip }

        it "returns an array containing data for both the skip condition and the secondary skip condition" do
          expect(step_summary_table_service.route_content).to eq [
            {
              answer_value: "Second branch",
              answer_value_cy: "Second branch (Welsh)",
              check_page: "2. Branch question (start of a route)",
              check_page_cy: "2. Branch question (start of a route) (Welsh)",
              exit_page: false,
              exit_page_heading: nil,
              exit_page_heading_cy: nil,
              exit_page_markdown: nil,
              exit_page_markdown_cy: nil,
              goto_page: "5. Question at the start of branch 2 (end of a route)",
              goto_page_cy: "5. Question at the start of branch 2 (end of a route) (Welsh)",
              routing_page: "2. Branch question (start of a route)",
              routing_page_cy: "2. Branch question (start of a route) (Welsh)",
              secondary_skip: false,
            },
            {
              answer_value: nil,
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
              secondary_skip: true,
            },
          ]
        end
      end

      context "when a page has a route which skips to the end of the form" do
        let(:page) { page_with_skip_to_end }

        it "returns an array containing condition data including text about skipping to the end of the form" do
          expect(step_summary_table_service.route_content).to eq [{ answer_value: "Skip to end",
                                                                    answer_value_cy: "Skip to end (Welsh)",
                                                                    check_page: "11. Question to be skipped",
                                                                    check_page_cy: "11. Question to be skipped (Welsh)",
                                                                    exit_page: false,
                                                                    exit_page_heading: nil,
                                                                    exit_page_heading_cy: nil,
                                                                    exit_page_markdown: nil,
                                                                    exit_page_markdown_cy: nil,
                                                                    goto_page: "End of the form",
                                                                    goto_page_cy: "End of the form",
                                                                    routing_page: "11. Question to be skipped",
                                                                    routing_page_cy: "11. Question to be skipped (Welsh)",
                                                                    secondary_skip: false }]
        end
      end

      context "when a page has a route with an exit page" do
        let(:page) { page_with_exit_page }

        it "returns an array containing condition and exit page data" do
          expect(step_summary_table_service.route_content).to eq [{ answer_value: "Exit",
                                                                    answer_value_cy: "Exit (Welsh)",
                                                                    check_page: "13. Exit page question",
                                                                    check_page_cy: "13. Exit page question (Welsh)",
                                                                    exit_page: true,
                                                                    exit_page_heading: "Exit page heading",
                                                                    exit_page_heading_cy: "Exit page heading (Welsh)",
                                                                    exit_page_markdown: "Exit page markdown",
                                                                    exit_page_markdown_cy: "Exit page markdown (Welsh)",
                                                                    goto_page: "Exit page heading",
                                                                    goto_page_cy: "Exit page heading (Welsh)",
                                                                    routing_page: "13. Exit page question",
                                                                    routing_page_cy: "13. Exit page question (Welsh)",
                                                                    secondary_skip: false }]
        end
      end

      context "when a page has a route based on a none of the above answer" do
        let(:page) { page_with_none_of_the_above }

        it "returns an array containing the none of the above answer" do
          expect(step_summary_table_service.route_content).to eq [{ answer_value: "None of the above",
                                                                    answer_value_cy: "Dim un o’r uchod",
                                                                    goto_page: "End of the form",
                                                                    goto_page_cy: "End of the form",
                                                                    routing_page: "14. Question with none of the above",
                                                                    routing_page_cy: "14. Question with none of the above (Welsh)",
                                                                    check_page: "14. Question with none of the above",
                                                                    check_page_cy: "14. Question with none of the above (Welsh)",
                                                                    secondary_skip: false,
                                                                    exit_page: false,
                                                                    exit_page_heading: nil,
                                                                    exit_page_heading_cy: nil,
                                                                    exit_page_markdown: nil,
                                                                    exit_page_markdown_cy: nil }]
        end
      end
    end
  end
end
