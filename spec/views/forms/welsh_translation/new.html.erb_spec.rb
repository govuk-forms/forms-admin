require "rails_helper"

describe "forms/welsh_translation/new.html.erb" do
  let(:form) { build_form }
  let(:page) { create :page, position: 1 }
  let(:another_page) { create :page, position: 2 }
  let(:condition) { create :condition, :with_exit_page, routing_page_id: page.id }
  let(:welsh_condition_translation_input) { Forms::WelshConditionTranslationInput.new(condition:).assign_condition_values }
  let(:welsh_page_translation_input) { Forms::WelshPageTranslationInput.new(page:).assign_page_values }
  let(:another_welsh_page_translation_input) { Forms::WelshPageTranslationInput.new(page: another_page).assign_page_values }
  let(:welsh_translation_input) { Forms::WelshTranslationInput.new(form:, page_translations: [welsh_page_translation_input, another_welsh_page_translation_input]).assign_form_values }
  let(:table_presenter) { Forms::TranslationTablePresenter.new }
  let(:mark_complete) { "true" }
  let(:welsh_translation_delete_path) { "/welsh-translation/delete" }
  let(:welsh_translation_download_path) { "/welsh-translation/download" }
  let(:has_welsh_translation?) { false }

  def build_form(attributes = {})
    default_attributes = {
      id: 1,
      name: "My form",
      name_cy: "My Welsh form",
      what_happens_next_markdown: "English what happens next",
      what_happens_next_markdown_cy: "Welsh what happens next",
      privacy_policy_url: "https://www.gov.uk/privacy",
      privacy_policy_url_cy: "https://www.gov.uk/privacy_cy",
      payment_url: "https://www.gov.uk/payment",
      payment_url_cy: "https://www.gov.uk/payment_cy",
      support_email: "support@example.gov.uk",
      support_phone: "English support phone",
      support_url: "https://www.gov.uk/support",
      support_url_text: "Support URL text",
      declaration_markdown: "Declaration markdown", # no welsh version to test nil
      pages: [page, another_page],
    }
    build(:form, default_attributes.merge(attributes))
  end

  before do
    welsh_translation_input.mark_complete = mark_complete
    allow(view).to receive_messages(welsh_translation_delete_path:, welsh_translation_download_path:)
    allow(form).to receive(:has_welsh_translation?).and_return(has_welsh_translation?)
    assign(:table_presenter, table_presenter)
  end

  context "when the form has no errors" do
    before do
      assign(:welsh_translation_input, welsh_translation_input)
      render
    end

    it "contains page heading and sub-heading" do
      expect(rendered).to have_css("h1 .govuk-caption-l", text: form.name)
      expect(rendered).to have_css("h1.govuk-heading-l", text: "Add a Welsh version of your form")
    end

    it "contains a link to preview the Welsh form" do
      expect(rendered).to have_link(t("forms.welsh_translation.new.preview_link_text"), href: preview_link(form, locale: :cy))
    end

    it "renders a text input for 'Form name'" do
      expect(rendered).to have_field("Enter your Welsh form name", type: "text", with: "My Welsh form")
    end

    it "renders english text for 'Form name'" do
      expect(rendered).to have_text("My form")
    end

    it "renders a text area for 'Declaration'" do
      expect(rendered).to have_field("Enter your Welsh declaration", type: "textarea", with: nil)
    end

    it "renders english text for 'Declaration'" do
      expect(rendered).to have_text("Declaration markdown")
    end

    it "renders a text area for 'What happens next'" do
      expect(rendered).to have_field("Enter information about what happens next in Welsh", type: "textarea", with: "Welsh what happens next")
    end

    it "renders english text for 'What happens next'" do
      expect(rendered).to have_text("English what happens next")
    end

    it "renders a text input for 'Privacy policy URL'" do
      expect(rendered).to have_field("Enter link to your Welsh privacy information", type: "text", with: "https://www.gov.uk/privacy_cy")
    end

    it "renders english text for 'Privacy policy URL'" do
      expect(rendered).to have_text("https://www.gov.uk/privacy")
    end

    it "renders a text input for 'Link to a payment page'" do
      expect(rendered).to have_field("Enter Welsh GOV.UK Pay payment link", type: "text", with: "https://www.gov.uk/payment_cy")
    end

    it "renders english text for 'Link to a payment page'" do
      expect(rendered).to have_text("https://www.gov.uk/payment")
    end

    it "renders text inputs for all the support contact fields" do
      expect(rendered).to have_field("Enter email address for Welsh support", type: "email")
      expect(rendered).to have_field("Enter phone information for Welsh support", type: "textarea")
      expect(rendered).to have_field("Enter an online contact link for Welsh support", type: "text")
      expect(rendered).to have_field("Enter text to describe the contact link for Welsh support", type: "text")
    end

    it "renders english text for support contact fields" do
      expect(rendered).to have_text("support@example.gov.uk")
      expect(rendered).to have_text("English support phone")
      expect(rendered).to have_text("https://www.gov.uk/support")
      expect(rendered).to have_text("Support URL text")
    end

    it "renders radio buttons for 'finished adding your Welsh version?'" do
      expect(rendered).to have_css("legend", text: "Have you finished adding your Welsh version?")
      expect(rendered).to have_field("Yes", type: "radio")
      expect(rendered).to have_field("No", type: "radio")
    end

    it "renders a 'Save and continue' button" do
      expect(rendered).to have_button("Save and continue")
    end

    it "does not render a link to delete the translation" do
      expect(rendered).not_to have_link(href: welsh_translation_delete_path)
    end

    it "renders all of the translation form fields with the welsh lang attribute" do
      form_fields = Capybara.string(rendered).find_all(".app-translation-table .govuk-form-group")

      expect(form_fields).not_to be_empty

      expect(form_fields).to all(have_css("[lang='cy']"))
    end

    it "renders a button to download the form as a CSV" do
      expect(rendered).to have_link(t("forms.welsh_translation.new.csv_download"), href: welsh_translation_download_path)
    end

    context "when the form already has a Welsh translation" do
      let(:has_welsh_translation?) { true }

      it "renders a link to delete the translation" do
        expect(rendered).to have_link(t("forms.welsh_translation.new.delete_welsh_version"), href: welsh_translation_delete_path, class: "govuk-button--warning")
      end
    end

    context "when the form does not have a declaration markdown" do
      let(:form) { build_form(declaration_markdown: nil) }

      it "does not render a declaration text area" do
        expect(rendered).not_to have_field("Declaration", type: "textarea")
      end

      it "renders message for no declaration text" do
        expect(rendered).to have_text("No declaration has been added to the form.")
      end
    end

    context "when the form has no payment URL" do
      let(:form) { build_form(payment_url: nil) }

      it "does not render a payment URL text input" do
        expect(rendered).not_to have_field("Payment URL", type: "text")
      end
    end

    context "when the form has no support URL" do
      let(:form) { build_form(support_url: nil) }

      it "does not render a support URL text input" do
        expect(rendered).not_to have_field("Support URL", type: "text")
        expect(rendered).not_to have_field("Support URL text", type: "text")
      end
    end

    context "when the form has no support phone" do
      let(:form) { build_form(support_phone: nil) }

      it "does not render a support phone text area" do
        expect(rendered).not_to have_field("Support phone", type: "textarea")
      end
    end

    context "when the form has no support email" do
      let(:form) { build_form(support_email: nil) }

      it "does not render a support email text input" do
        expect(rendered).not_to have_field("Support email", type: "text")
      end
    end

    context "when the form has no support information" do
      let(:form) { build_form(support_email: nil, support_phone: nil, support_url: nil, support_url_text: nil) }

      it "does not render support information" do
        expect(rendered).not_to have_text("Contact details for support", exact: true)
      end

      it "renders message for no support information" do
        expect(rendered).to have_text("No contact details for support have been added to the form yet.")
      end
    end

    context "when the form has no what happens next information" do
      let(:form) { build_form(what_happens_next_markdown: nil) }

      it "does not render what happens next information" do
        expect(rendered).not_to have_field("What happens next", type: "textarea")
      end

      it "renders message for no what happens next information" do
        expect(rendered).to have_text("No information about what happens next has been added to the form yet.")
      end
    end

    context "when the form has no privacy information" do
      let(:form) { build_form(privacy_policy_url: nil) }

      it "does not render privacy information field" do
        expect(rendered).not_to have_field("Privacy policy URL", type: "text")
      end

      it "renders message for no privacy information" do
        expect(rendered).to have_text("No privacy information has been added to the form yet.")
      end
    end

    context "when the form does not have any pages" do
      let(:form) { build_form(pages: []) }
      let(:welsh_translation_input) { Forms::WelshTranslationInput.new(form:, page_translations: []).assign_form_values }

      it "does not render any page translation content" do
        expect(rendered).not_to have_field(id: "page_#{page.id}_question_text_cy", type: "text")
      end

      it "renders message for no pages" do
        expect(rendered).to have_text("No questions have been added to the form yet.")
      end
    end

    context "when the form has pages" do
      it "has a field for each page's Welsh question text" do
        expect(rendered).to have_field("Enter Welsh question text for question #{page.position}", type: "text", id: "page_#{page.id}_question_text_cy")
        expect(rendered).to have_field("Enter Welsh question text for question #{another_page.position}", type: "text", id: "page_#{another_page.id}_question_text_cy")
      end

      context "when a page has hint text" do
        let(:page) { create :page, hint_text: "Choose 'Yes' if you already have a valid licence." }
        let(:another_page) { create :page, hint_text: nil }

        it "shows the English text and Welsh field for pages with English hint text" do
          expect(rendered).to have_css("td", text: page.hint_text)
          expect(rendered).to have_field("Enter Welsh hint text for question #{page.position}", type: "textarea", id: "page_#{page.id}_hint_text_cy")
        end

        it "does not show the Welsh field for pages without English hint text" do
          expect(rendered).not_to have_field("Enter Welsh hint text for question #{another_page.position}")
        end
      end

      context "when a page has a page heading and guidance markdown" do
        let(:page) { create :page, guidance_markdown: nil, page_heading: nil }
        let(:another_page) { create :page, guidance_markdown: "This part of the form concerns licencing.", page_heading: "Licencing" }

        it "shows the English text and Welsh fields for pages with English page heading and guidance markdown" do
          expect(rendered).to have_css("td", text: another_page.page_heading)
          expect(rendered).to have_field("Enter Welsh page heading for question #{another_page.position}", id: "page_#{another_page.id}_page_heading_cy")
          expect(rendered).to have_css("td", text: another_page.guidance_markdown)
          expect(rendered).to have_field("Enter Welsh guidance text for question #{another_page.position}", id: "page_#{another_page.id}_guidance_markdown_cy")
        end

        it "does not show the Welsh field for pages without English page heading and guidance markdown" do
          expect(rendered).not_to have_field("Enter Welsh page heading for question #{page.position}")
          expect(rendered).not_to have_field("Enter Welsh guidance text for question #{page.position}", type: "textarea")
        end
      end

      context "when a page has a selection question" do
        let(:page) { create :page, :with_selection_settings }

        it "shows the selection heading" do
          expect(rendered).to have_css("caption", text: t("forms.welsh_translation.new.section_headings.selection_options", question_number: page.position))
        end

        it "shows the English text and Welsh field for pages with English selection options" do
          expect(rendered).to have_css("td", text: page.answer_settings.selection_options.first["name"])
          expect(rendered).to have_field("Enter Welsh option 1")

          expect(rendered).to have_css("td", text: page.answer_settings.selection_options.second["name"])
          expect(rendered).to have_field("Enter Welsh option 2")
        end
      end

      context "when a page has a selection question with none of the above" do
        let(:page) { create :page, :selection_with_none_of_the_above_question }

        it "has row for the none of the above question text" do
          expect(rendered).to have_css("th", text: t("forms.welsh_translation.new.none_of_the_above_question"))
        end

        it "shows the English text and Welsh field for none of the above question" do
          expect(rendered).to have_css("td", text: page.answer_settings.none_of_the_above_question.question_text)
          expect(rendered).to have_field("Enter Welsh question or label if ‘None of the above’ is selected")
        end
      end

      context "when at least one page has routing conditions" do
        context "when the condition has an exit page" do
          let(:page) { create :page, position: 1, routing_conditions: [condition] }
          let(:condition) { create :condition, :with_exit_page }

          it "shows a caption with the page the condition applies to" do
            expect(rendered).to have_css("caption", text: t("forms.welsh_translation.new.condition.heading", question_number: condition.routing_page.position))
          end

          it "shows the English text and Welsh field for each condition's exit page fields" do
            expect(rendered).to have_css("td", text: condition.exit_page_heading)
            expect(rendered).to have_field("Enter Welsh exit page heading for question #{condition.routing_page.position}", type: "text", id: welsh_condition_translation_input.form_field_id(:exit_page_heading_cy))
            expect(rendered).to have_css("td", text: condition.exit_page_markdown)
            expect(rendered).to have_field("Enter Welsh exit page content for question #{condition.routing_page.position}", type: "textarea", id: welsh_condition_translation_input.form_field_id(:exit_page_markdown_cy))
          end
        end
      end
    end
  end

  context "when the form has validation errors" do
    let(:mark_complete) { nil }

    before do
      welsh_translation_input.validate

      assign(:welsh_translation_input, welsh_translation_input)
      render
    end

    it "displays an error summary box" do
      expect(rendered).to have_css(".govuk-error-summary")
      expect(rendered).to have_css("h2.govuk-error-summary__title", text: "There is a problem")
    end

    it "links the error summary to the invalid field" do
      error_message = I18n.t("activemodel.errors.models.forms/welsh_translation_input.attributes.mark_complete.blank")
      expect(rendered).to have_link(error_message, href: "#forms-welsh-translation-input-mark-complete-field-error")
    end

    it "adds an inline error message to the invalid field" do
      error_message = "Error: #{I18n.t('activemodel.errors.models.forms/welsh_translation_input.attributes.mark_complete.blank')}"
      expect(rendered).to have_css(".govuk-error-message", text: error_message)
    end
  end

  context "when a page translation has validation errors" do
    before do
      welsh_page_translation_input.question_text_cy = nil
      welsh_translation_input.validate(mark_complete ? :mark_complete : nil)

      assign(:welsh_translation_input, welsh_translation_input)
      render
    end

    it "displays an error summary box" do
      expect(rendered).to have_css(".govuk-error-summary")
      expect(rendered).to have_css("h2.govuk-error-summary__title", text: "There is a problem")
    end

    it "links the error summary to the invalid field" do
      error_message = I18n.t("activemodel.errors.models.forms/welsh_page_translation_input.attributes.question_text_cy.blank", question_number: page.position)
      expect(rendered).to have_link(error_message, href: "#page_#{page.id}_question_text_cy")
    end

    it "adds an inline error message to the invalid field" do
      error_message = "Error: #{I18n.t('activemodel.errors.models.forms/welsh_page_translation_input.attributes.question_text_cy.blank', question_number: page.position)}"
      expect(rendered).to have_css(".govuk-error-message", text: error_message)
    end
  end

  context "when a condition translation has validation errors" do
    let(:page) { create :page, position: 1, routing_conditions: [condition] }
    let(:condition) { create :condition, :with_exit_page, answer_value: "Yes" }

    before do
      welsh_condition_translation_input.exit_page_heading_cy = nil
      welsh_translation_input.validate(mark_complete ? :mark_complete : nil)

      assign(:welsh_translation_input, welsh_translation_input)
      render
    end

    it "displays an error summary box" do
      expect(rendered).to have_css(".govuk-error-summary")
      expect(rendered).to have_css("h2.govuk-error-summary__title", text: "There is a problem")
    end

    it "links the error summary to the invalid field" do
      error_message = I18n.t("activemodel.errors.models.forms/welsh_condition_translation_input.attributes.exit_page_heading_cy.blank", question_number: page.position)
      expect(rendered).to have_link(error_message, href: "#condition_#{condition.id}_exit_page_heading_cy")
    end

    it "adds an inline error message to the invalid field" do
      error_message = "Error: #{I18n.t('activemodel.errors.models.forms/welsh_condition_translation_input.attributes.exit_page_heading_cy.blank', question_number: page.position)}"
      expect(rendered).to have_css(".govuk-error-message", text: error_message)
    end
  end
end
