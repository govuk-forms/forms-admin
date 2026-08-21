require "rails_helper"

RSpec.describe Forms::WelshTranslationInput, type: :model do
  subject(:welsh_translation_input) { described_class.new(new_input_data) }

  let(:form) { build_form }
  let(:page) do
    create :page,
           question_text: "Are you renewing a licence?",
           hint_text: "Choose 'Yes' if you already have a valid licence.",
           page_heading: "Licencing",
           guidance_markdown: "This part of the form concerns licencing.",
           position: 1
  end
  let(:another_page) { create :page, position: 2 }

  let(:mark_complete) { "true" }

  let(:new_input_data) do
    {
      form:,
      mark_complete:,
      name_cy: "New Welsh name",
      what_happens_next_markdown_cy: "New Welsh what happens next",
      declaration_markdown_cy: "New Welsh declaration",
      support_email_cy: "new-welsh-support@example.gov.uk",
      support_phone_cy: "0800 123 4567",
      support_url_cy: "https://www.gov.uk/new-welsh-support",
      support_url_text_cy: "New Welsh Support",
      privacy_policy_url_cy: "https://www.gov.uk/new-welsh-privacy",
      payment_url_cy: "https://www.gov.uk/payments/new-welsh-payment-link",
    }
  end

  def build_form(attributes = {})
    default_attributes = {
      id: 1,
      name: "Apply for a juggling licence",
      what_happens_next_markdown: "English what happens next",
      welsh_completed: false,
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
      privacy_policy_url_cy: "https://www.gov.uk/welsh-privacy",
      payment_url: "https://www.gov.uk/english-payment",
      payment_url_cy: "https://www.gov.uk/payments/your-welsh-payment-link",
    }
    build(:form, :with_group, default_attributes.merge(attributes))
  end

  def build_empty_welsh_form
    empty_attributes = {
      id: 1,
      name: "Apply for a juggling licence",
      what_happens_next_markdown: "English what happens next",
      welsh_completed: false,
      what_happens_next_markdown_cy: "",
      declaration_text: "English declaration",
      declaration_text_cy: "",
      support_email: "english-support@example.gov.uk",
      support_email_cy: "",
      support_phone: "01234 987654",
      support_phone_cy: "",
      support_url_cy: "",
      support_url: "https://www.gov.uk/english-support",
      support_url_text_cy: "",
      support_url_text: "English Support",
      privacy_policy_url_cy: "",
      payment_url: "https://www.gov.uk/english-payment",
      payment_url_cy: "",
    }
    build(:form, empty_attributes)
  end

  describe "validations" do
    it "is not valid if mark complete is blank" do
      form = OpenStruct.new(welsh_completed: false, name: "Apply for a juggling licence")
      welsh_translation_input = described_class.new(mark_complete: nil, form:)

      expect(welsh_translation_input).not_to be_valid
      expect(welsh_translation_input.errors.full_messages_for(:mark_complete)).to include "Mark complete #{I18n.t('activemodel.errors.models.forms/welsh_translation_input.attributes.mark_complete.blank')}"
    end

    context "when the form is marked complete" do
      let(:mark_complete) { "true" }

      context "when the Welsh form name is present" do
        context "when the Welsh form name is 500 characters or fewer" do
          let(:new_input_data) { super().merge(name_cy: "A form".ljust(500, "x")) }

          it "is valid" do
            expect(welsh_translation_input).to be_valid
          end
        end

        context "when the Welsh form name is 501 characters or more" do
          let(:new_input_data) { super().merge(name_cy: "A form".ljust(501, "x")) }

          it "is not valid" do
            expect(welsh_translation_input).not_to be_valid
            expect(welsh_translation_input.errors.full_messages_for(:name_cy)).to include "Name cy #{I18n.t('activemodel.errors.models.forms/welsh_translation_input.attributes.name_cy.too_long', count: 500)}"
          end
        end
      end

      context "when the Welsh form name is missing" do
        let(:new_input_data) { super().merge(name_cy: nil) }

        it "is not valid when the Welsh form name is missing" do
          expect(welsh_translation_input).not_to be_valid
          expect(welsh_translation_input.errors.full_messages_for(:name_cy)).to include "Name cy #{I18n.t('activemodel.errors.models.forms/welsh_translation_input.attributes.name_cy.blank')}"
        end
      end

      describe "Welsh privacy policy URL" do
        context "when the Welsh privacy policy URL is present" do
          context "when the Welsh privacy policy is a valid link" do
            let(:new_input_data) { super().merge(privacy_policy_url_cy: "https://www.gov.uk/welsh-privacy") }

            it "is valid" do
              expect(welsh_translation_input).to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:privacy_policy_url_cy)).to be_empty
            end
          end

          context "when the Welsh privacy policy is a link to the example" do
            let(:new_input_data) { super().merge(privacy_policy_url_cy: "https://www.gov.uk/help/privacy-notice") }

            it "is invalid" do
              expect(welsh_translation_input).not_to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:privacy_policy_url_cy)).to include "Privacy policy url cy #{I18n.t('activemodel.errors.models.forms/welsh_translation_input.attributes.privacy_policy_url_cy.exclusion')}"
            end
          end

          context "when the Welsh privacy policy is not a URL" do
            let(:new_input_data) { super().merge(privacy_policy_url_cy: "Something that isn't a URL") }

            it "is invalid" do
              expect(welsh_translation_input).not_to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:privacy_policy_url_cy)).to include "Privacy policy url cy #{I18n.t('activemodel.errors.models.forms/welsh_translation_input.attributes.privacy_policy_url_cy.url')}"
            end
          end
        end

        context "when the Welsh privacy policy URL is missing" do
          let(:new_input_data) { super().merge(privacy_policy_url_cy: nil) }

          context "when the form has a privacy policy URL in English" do
            it "is not valid" do
              expect(welsh_translation_input).not_to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:privacy_policy_url_cy)).to include "Privacy policy url cy #{I18n.t('activemodel.errors.models.forms/welsh_translation_input.attributes.privacy_policy_url_cy.blank')}"
            end
          end

          context "when the form does not have a privacy policy URL in English" do
            let(:form) { build_form(privacy_policy_url: nil) }

            it "is valid" do
              expect(welsh_translation_input).to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:privacy_policy_url_cy)).to be_empty
            end
          end
        end
      end

      describe "Welsh support email" do
        context "when the Welsh support email is present" do
          it_behaves_like "a field that rejects invalid email addresses" do
            let(:model) { welsh_translation_input }
            let(:attribute) { :support_email_cy }
          end

          context "when the Welsh support email is a valid Government email address" do
            let(:new_input_data) { super().merge(support_email_cy: "someone@example.gov.uk") }

            it "is valid" do
              expect(welsh_translation_input).to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:support_email_cy)).to be_empty
            end
          end

          context "when the Welsh support email is a correctly formatted email address with a non-government domain" do
            let(:new_input_data) { super().merge(support_email_cy: "someone@example.com") }

            it "is invalid" do
              expect(welsh_translation_input).not_to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:support_email_cy)).to include "Support email cy #{I18n.t('activemodel.errors.models.forms/welsh_translation_input.attributes.support_email_cy.non_government_email')}"
            end

            context "and the organisation has an associated domain matching the email" do
              before do
                create :organisation_domain, organisation: form.group.organisation, domain: "example.com"
              end

              it "is valid" do
                expect(welsh_translation_input).to be_valid
              end
            end
          end
        end

        context "when the Welsh support email is missing" do
          let(:new_input_data) { super().merge(support_email_cy: nil) }

          context "when the form has a support email in English" do
            it "is not valid" do
              expect(welsh_translation_input).not_to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:support_email_cy)).to include "Support email cy #{I18n.t('activemodel.errors.models.forms/welsh_translation_input.attributes.support_email_cy.blank')}"
            end
          end

          context "when the form does not have a support email in English" do
            let(:form) { build_form(support_email: nil) }

            it "is valid" do
              expect(welsh_translation_input).to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:support_email_cy)).to be_empty
            end
          end
        end
      end

      describe "Welsh support phone number" do
        context "when the Welsh support phone number is present" do
          context "when the Welsh support phone number is 500 characters or fewer" do
            let(:new_input_data) { super().merge(support_phone_cy: "01632 960051\nOpening hours: 9am-5pm".ljust(500, "x")) }

            it "is valid" do
              expect(welsh_translation_input).to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:support_phone_cy)).to be_empty
            end
          end

          context "when the Welsh support phone number is 501 characters or more" do
            let(:new_input_data) { super().merge(support_phone_cy: "01632 960051\nOpening hours: 9am-5pm".ljust(501, "x")) }

            it "is invalid" do
              expect(welsh_translation_input).not_to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:support_phone_cy)).to include "Support phone cy #{I18n.t('activemodel.errors.models.forms/welsh_translation_input.attributes.support_phone_cy.too_long')}"
            end
          end
        end

        context "when the Welsh support phone number is missing" do
          let(:new_input_data) { super().merge(support_phone_cy: nil) }

          context "when the form has a support phone number in English" do
            it "is not valid" do
              expect(welsh_translation_input).not_to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:support_phone_cy)).to include "Support phone cy #{I18n.t('activemodel.errors.models.forms/welsh_translation_input.attributes.support_phone_cy.blank')}"
            end
          end

          context "when the form does not have a support phone number in English" do
            let(:form) { build_form(support_phone: nil) }

            it "is valid" do
              expect(welsh_translation_input).to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:support_phone_cy)).to be_empty
            end
          end
        end
      end

      describe "Welsh support link" do
        context "when the Welsh support link is present" do
          context "when the link URL is 120 characters or fewer" do
            let(:new_input_data) { super().merge(support_url_cy: "https://example.org/".ljust(120, "x")) }

            it "is valid" do
              expect(welsh_translation_input).to be_valid
            end
          end

          context "when the link URL is 120 characters or more" do
            let(:new_input_data) { super().merge(support_url_cy: "https://example.org/".ljust(121, "x")) }

            it "is invalid" do
              error_message = I18n.t("activemodel.errors.models.forms/welsh_translation_input.attributes.support_url_cy.too_long")
              expect(welsh_translation_input).to be_invalid
              expect(welsh_translation_input.errors.full_messages_for(:support_url_cy)).to include "Support url cy #{error_message}"
            end
          end

          context "when the link URL is not in a valid URL format" do
            let(:new_input_data) { super().merge(support_url_cy: "not a URL") }

            it "link_href is invalid if not a URL" do
              error_message = I18n.t("activemodel.errors.models.forms/welsh_translation_input.attributes.support_url_cy.url")
              expect(welsh_translation_input).to be_invalid
              expect(welsh_translation_input.errors.full_messages_for(:support_url_cy)).to include "Support url cy #{error_message}"
            end
          end
        end

        context "when the Welsh support url is missing" do
          let(:new_input_data) { super().merge(support_url_cy: nil) }

          context "when the form has a support url in English" do
            it "is not valid" do
              expect(welsh_translation_input).not_to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:support_url_cy)).to include "Support url cy #{I18n.t('activemodel.errors.models.forms/welsh_translation_input.attributes.support_url_cy.blank')}"
            end
          end

          context "when the form does not have a support_url in English" do
            let(:form) { build_form(support_url: nil) }

            it "is valid" do
              expect(welsh_translation_input).to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:support_url_cy)).to be_empty
            end
          end
        end

        context "when the Welsh support link text is present" do
          context "when the link text is 120 characters or fewer" do
            let(:new_input_data) { super().merge(support_url_text_cy: "Online contact form".ljust(120, "x")) }

            it "is valid" do
              expect(welsh_translation_input).to be_valid
            end
          end

          context "when the link text is 120 characters or more" do
            let(:new_input_data) { super().merge(support_url_text_cy: "Online contact form".ljust(121, "x")) }

            it "is invalid" do
              error_message = I18n.t("activemodel.errors.models.forms/welsh_translation_input.attributes.support_url_text_cy.too_long")
              expect(welsh_translation_input).to be_invalid
              expect(welsh_translation_input.errors.full_messages_for(:support_url_text_cy)).to include "Support url text cy #{error_message}"
            end
          end
        end

        context "when the Welsh support link text is missing" do
          let(:new_input_data) { super().merge(support_url_text_cy: nil) }

          context "when the form has a support url in English" do
            it "is not valid" do
              expect(welsh_translation_input).not_to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:support_url_text_cy)).to include "Support url text cy #{I18n.t('activemodel.errors.models.forms/welsh_translation_input.attributes.support_url_text_cy.blank')}"
            end
          end

          context "when the form does not have a support_url in English" do
            let(:form) { build_form(support_url: nil) }

            it "is valid" do
              expect(welsh_translation_input).to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:support_url_text_cy)).to be_empty
            end
          end
        end
      end

      context "when the Welsh declaration markdown is present" do
        context "when the Welsh declaration markdown is 2000 characters or fewer" do
          let(:new_input_data) { super().merge(declaration_markdown_cy: "By submitting this form you’re confirming that, to the best of your knowledge, the answers you’re providing are correct.".ljust(2000, "x")) }

          it "is valid" do
            expect(welsh_translation_input).to be_valid
          end
        end

        context "when the Welsh declaration markdown is 2001 characters or more" do
          let(:new_input_data) { super().merge(declaration_markdown_cy: "By submitting this form you’re confirming that, to the best of your knowledge, the answers you’re providing are correct.".ljust(2001, "x")) }

          it "is invalid" do
            expect(welsh_translation_input).not_to be_valid
            expect(welsh_translation_input.errors.full_messages_for(:declaration_markdown_cy)).to include "Declaration markdown cy #{I18n.t('activemodel.errors.models.forms/welsh_translation_input.attributes.declaration_markdown_cy.too_long')}"
          end
        end
      end

      context "when the Welsh declaration markdown is missing" do
        let(:new_input_data) { super().merge(declaration_markdown_cy: nil) }

        context "when the form has declaration text in English" do
          it "is not valid" do
            expect(welsh_translation_input).not_to be_valid
            expect(welsh_translation_input.errors.full_messages_for(:declaration_markdown_cy)).to include "Declaration markdown cy #{I18n.t('activemodel.errors.models.forms/welsh_translation_input.attributes.declaration_markdown_cy.blank')}"
          end
        end

        context "when the form does not have declaration text in English" do
          let(:form) { build_form(declaration_markdown: nil) }

          it "is valid" do
            expect(welsh_translation_input).to be_valid
            expect(welsh_translation_input.errors.full_messages_for(:declaration_markdown_cy)).to be_empty
          end
        end
      end

      describe "what_happens_next_markdown_cy" do
        it_behaves_like "a markdown field with headings disallowed" do
          let(:model) { welsh_translation_input }
          let(:attribute) { :what_happens_next_markdown_cy }
        end

        context "when the Welsh what happens next markdown is missing" do
          let(:new_input_data) { super().merge(what_happens_next_markdown_cy: nil) }

          context "when the form has what_happens_next_markdown in English" do
            it "is not valid" do
              expect(welsh_translation_input).not_to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:what_happens_next_markdown_cy)).to include "What happens next markdown cy #{I18n.t('activemodel.errors.models.forms/welsh_translation_input.attributes.what_happens_next_markdown_cy.blank')}"
            end
          end

          context "when the form does not have what_happens_next_markdown in English" do
            let(:form) { build_form(what_happens_next_markdown: nil) }

            it "is valid" do
              expect(welsh_translation_input).to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:what_happens_next_markdown_cy)).to be_empty
            end
          end
        end
      end

      describe "Welsh payment link" do
        context "when the Welsh payment URL is present" do
          it_behaves_like "a payment link validator" do
            let(:model) { welsh_translation_input }
            let(:attribute) { :payment_url_cy }
          end

          context "when the payment link is not a url" do
            let(:new_input_data) { super().merge(payment_url_cy: "Something that isn't a URL") }

            it "is invalid" do
              expect(welsh_translation_input).not_to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:payment_url_cy)).to include "Payment url cy #{I18n.t('activemodel.errors.models.forms/welsh_translation_input.attributes.payment_url_cy.url')}"
            end
          end
        end

        context "when the Welsh payment URL is missing" do
          let(:new_input_data) { super().merge(payment_url_cy: nil) }

          context "when the form has a payment url in English" do
            it "is not valid" do
              expect(welsh_translation_input).not_to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:payment_url_cy)).to include "Payment url cy #{I18n.t('activemodel.errors.models.forms/welsh_translation_input.attributes.payment_url_cy.blank')}"
            end
          end

          context "when the form does not have a payment_url_cy in English" do
            let(:form) { build_form(payment_url: nil) }

            it "is valid" do
              expect(welsh_translation_input).to be_valid
              expect(welsh_translation_input.errors.full_messages_for(:payment_url_cy)).to be_empty
            end
          end
        end
      end
    end

    context "when the form is not marked complete" do
      let(:mark_complete) { "false" }

      context "when the Welsh form name is missing" do
        let(:new_input_data) { super().merge(name_cy: nil) }

        it "is not valid when the Welsh form name is missing" do
          expect(welsh_translation_input).to be_valid
          expect(welsh_translation_input.errors.full_messages_for(:name_cy)).to be_empty
        end
      end

      context "when the Welsh privacy_policy_url is missing" do
        let(:new_input_data) { super().merge(privacy_policy_url_cy: nil) }

        it "is valid" do
          expect(welsh_translation_input).to be_valid
          expect(welsh_translation_input.errors.full_messages_for(:privacy_policy_url_cy)).to be_empty
        end
      end

      context "when the Welsh support email is missing" do
        let(:new_input_data) { super().merge(support_email_cy: nil) }

        it "is valid" do
          expect(welsh_translation_input).to be_valid
          expect(welsh_translation_input.errors.full_messages_for(:support_email_cy)).to be_empty
        end
      end

      context "when the Welsh support phone number is missing" do
        let(:new_input_data) { super().merge(support_phone_cy: nil) }

        it "is valid" do
          expect(welsh_translation_input).to be_valid
          expect(welsh_translation_input.errors.full_messages_for(:support_phone_cy)).to be_empty
        end
      end

      context "when the Welsh support url is missing" do
        let(:new_input_data) { super().merge(support_url_cy: nil) }

        it "is valid" do
          expect(welsh_translation_input).to be_valid
          expect(welsh_translation_input.errors.full_messages_for(:support_url_cy)).to be_empty
        end
      end

      context "when the Welsh support link text is missing" do
        let(:new_input_data) { super().merge(support_url_text_cy: nil) }

        it "is valid" do
          expect(welsh_translation_input).to be_valid
          expect(welsh_translation_input.errors.full_messages_for(:support_url_text_cy)).to be_empty
        end
      end

      context "when the Welsh declaration text is missing" do
        let(:new_input_data) { super().merge(declaration_markdown_cy: nil) }

        it "is valid" do
          expect(welsh_translation_input).to be_valid
          expect(welsh_translation_input.errors.full_messages_for(:declaration_markdown_cy)).to be_empty
        end
      end

      context "when the Welsh what happens next markdown is missing" do
        let(:new_input_data) { super().merge(what_happens_next_markdown_cy: nil) }

        it "is valid" do
          expect(welsh_translation_input).to be_valid
          expect(welsh_translation_input.errors.full_messages_for(:what_happens_next_markdown_cy)).to be_empty
        end
      end

      context "when the Welsh payment_url_cy is missing" do
        let(:new_input_data) { super().merge(payment_url_cy: nil) }

        it "is valid" do
          expect(welsh_translation_input).to be_valid
          expect(welsh_translation_input.errors.full_messages_for(:payment_url_cy)).to be_empty
        end
      end
    end

    context "when any of the form's page translations have errors" do
      let(:page_translation) { Forms::WelshPageTranslationInput.new(page:) }
      let(:new_input_data) { super().merge(page_translations: [page_translation]) }

      it "includes the page error with a custom attribute" do
        expect(welsh_translation_input).not_to be_valid(:mark_complete)
        expect(welsh_translation_input.errors.full_messages_for(:page_1_question_text_cy)).to include "Page 1 question text cy #{I18n.t('activemodel.errors.models.forms/welsh_page_translation_input.attributes.question_text_cy.blank', question_number: page.position)}"
      end
    end
  end

  describe "#submit" do
    context "when the data is invalid" do
      let(:new_input_data) { super().merge(mark_complete: nil) }

      it "returns false" do
        expect(welsh_translation_input.submit).to be false
      end

      it "does not update the form's attributes" do
        original_attributes = form.attributes.clone
        welsh_translation_input.submit
        expect(form.attributes).to eq(original_attributes)
      end
    end

    context "when the data is valid" do
      it "returns true" do
        expect(welsh_translation_input.submit).to be true
      end

      it "updates the form's welsh attributes with the new values" do
        welsh_translation_input.submit

        expect(form.welsh_completed).to be true
        expect(form.what_happens_next_markdown_cy).to eq(new_input_data[:what_happens_next_markdown_cy])
        expect(form.declaration_markdown_cy).to eq(new_input_data[:declaration_markdown_cy])
        expect(form.support_email_cy).to eq(new_input_data[:support_email_cy])
        expect(form.support_phone_cy).to eq(new_input_data[:support_phone_cy])
        expect(form.support_url_cy).to eq(new_input_data[:support_url_cy])
        expect(form.support_url_text_cy).to eq(new_input_data[:support_url_text_cy])
        expect(form.privacy_policy_url_cy).to eq(new_input_data[:privacy_policy_url_cy])
        expect(form.payment_url_cy).to eq(new_input_data[:payment_url_cy])
      end

      it "does not update any non-welsh attributes" do
        english_value_before = form.what_happens_next_markdown
        welsh_translation_input.submit
        expect(form.what_happens_next_markdown).to eq(english_value_before)
      end

      it "adds :cy to the avaliable languages" do
        welsh_translation_input.submit
        expect(form.available_languages).to include("cy")
      end

      context "when the form has no declaration markdown" do
        let(:form) { build_form(declaration_markdown: nil) }

        it "clears the Welsh declaration text" do
          welsh_translation_input.submit
          expect(form.declaration_markdown_cy).to be_nil
        end
      end

      context "when the form has no payment URL" do
        let(:form) { build_form(payment_url: nil) }

        it "clears the Welsh payment URL" do
          welsh_translation_input.submit
          expect(form.payment_url_cy).to be_nil
        end
      end

      context "when the form has no support URL" do
        let(:form) { build_form(support_url: nil) }

        it "clears the Welsh support URL" do
          welsh_translation_input.submit
          expect(form.support_url_cy).to be_nil
        end

        it "clears the Welsh support URL text" do
          welsh_translation_input.submit
          expect(form.support_url_text_cy).to be_nil
        end
      end

      context "when the form has no support phone" do
        let(:form) { build_form(support_phone: nil) }

        it "clears the Welsh support phone" do
          welsh_translation_input.submit
          expect(form.support_phone_cy).to be_nil
        end
      end

      context "when the form has no support email" do
        let(:form) { build_form(support_email: nil) }

        it "clears the Welsh support email" do
          welsh_translation_input.submit
          expect(form.support_email_cy).to be_nil
        end
      end

      context "when the form includes page translation objects" do
        let(:page_translation) { Forms::WelshPageTranslationInput.new(page:, question_text_cy: "Ydych chi'n adnewyddu trwydded?", hint_text_cy: "Dewiswch 'Ydw' os oes gennych drwydded ddilys eisoes.", page_heading_cy: "Trwyddedu", guidance_markdown_cy: "Mae'r rhan hon o'r ffurflen yn ymwneud â thrwyddedu.") }
        let(:another_page_translation) { Forms::WelshPageTranslationInput.new(page: another_page, question_text_cy: "Ydych chi'n adnewyddu trwydded?") }

        let(:new_input_data) { super().merge(page_translations: [page_translation, another_page_translation]) }

        it "submits the data on the page translation objects" do
          welsh_translation_input.submit

          expect(page.reload.question_text_cy).to eq("Ydych chi'n adnewyddu trwydded?")
          expect(page.reload.hint_text_cy).to eq("Dewiswch 'Ydw' os oes gennych drwydded ddilys eisoes.")
          expect(another_page.reload.question_text_cy).to eq("Ydych chi'n adnewyddu trwydded?")
        end
      end
    end
  end

  describe "#assign_form_values" do
    it "loads the existing welsh attributes from the form" do
      welsh_translation_input = described_class.new(form:)
      welsh_translation_input.assign_form_values

      expect(welsh_translation_input.what_happens_next_markdown_cy).to eq(form.what_happens_next_markdown_cy)
      expect(welsh_translation_input.declaration_markdown_cy).to eq(form.declaration_markdown_cy)
      expect(welsh_translation_input.support_email_cy).to eq(form.support_email_cy)
      expect(welsh_translation_input.support_phone_cy).to eq(form.support_phone_cy)
      expect(welsh_translation_input.support_url_cy).to eq(form.support_url_cy)
      expect(welsh_translation_input.support_url_text_cy).to eq(form.support_url_text_cy)
      expect(welsh_translation_input.privacy_policy_url_cy).to eq(form.privacy_policy_url_cy)
      expect(welsh_translation_input.payment_url_cy).to eq(form.payment_url_cy)
      expect(welsh_translation_input.mark_complete).to eq(form.welsh_completed)
    end
  end

  describe "#assign_from_spreadsheet" do
    before do
      form.pages = [page, another_page]
    end

    context "when the spreadsheet data contains Welsh translations for all fields" do
      let(:spreadsheet_data) do
        {
          "Form name" => "Welsh A form from spreadsheet",
          "Question 1 - question text" => "Welsh question text from spreadsheet",
          "Question 1 - option 1" => "Welsh Option 1 from spreadsheet",
          "Question 1 - option 2" => "Welsh Option 2 from spreadsheet",
          "Question 1 - question or label if 'None of the above' is selected" => "Welsh None of the above question? from spreadsheet",
          "Question 1 - exit page heading" => "Welsh exit page heading from spreadsheet",
          "Question 1 - exit page content" => "Welsh exit page content from spreadsheet",
          "Question 2 - exit page 1 heading" => "Welsh question 2 exit page heading from spreadsheet",
          "Question 2 - exit page 1 content" => "Welsh question 2 exit page content from spreadsheet",
          "Question 2 - page heading" => "Welsh question 2 page heading from spreadsheet",
          "Question 2 - guidance text" => "Welsh question 2 guidance markdown from spreadsheet",
          "Question 2 - question text" => "Welsh question 2 text from spreadsheet",
          "Declaration" => "Welsh declaration text from spreadsheet",
          "Information about what happens next" => "Welsh what happens next from spreadsheet",
          "GOV.UK Pay payment link" => "https://www.gov.uk/payment_cy_spreadsheet",
          "Link to privacy information for this form" => "https://www.gov.uk/privacy_cy_spreadsheet",
          "Contact details for support - email address" => "support-spreadsheet@example.gov.wales",
          "Contact details for support - phone number and opening times" => "Welsh support phone from spreadsheet",
          "Contact details for support - online contact link" => "https://www.gov.uk/support_cy_spreadsheet",
          "Contact details for support - online contact link text" => "Welsh Support URL text from spreadsheet",
        }
      end

      it "sets the welsh attributes from the spreadsheet data" do
        welsh_translation_input = described_class.new(form:)
        welsh_translation_input.assign_from_spreadsheet(spreadsheet_data)

        expect(welsh_translation_input.name_cy).to eq("Welsh A form from spreadsheet")
        expect(welsh_translation_input.declaration_markdown_cy).to eq("Welsh declaration text from spreadsheet")
        expect(welsh_translation_input.what_happens_next_markdown_cy).to eq("Welsh what happens next from spreadsheet")
        expect(welsh_translation_input.payment_url_cy).to eq("https://www.gov.uk/payment_cy_spreadsheet")
        expect(welsh_translation_input.privacy_policy_url_cy).to eq("https://www.gov.uk/privacy_cy_spreadsheet")
        expect(welsh_translation_input.support_email_cy).to eq("support-spreadsheet@example.gov.wales")
        expect(welsh_translation_input.support_phone_cy).to eq("Welsh support phone from spreadsheet")
        expect(welsh_translation_input.support_url_cy).to eq("https://www.gov.uk/support_cy_spreadsheet")
        expect(welsh_translation_input.support_url_text_cy).to eq("Welsh Support URL text from spreadsheet")

        page_translation = welsh_translation_input.page_translations.find { |pt| pt.id == page.id }
        expect(page_translation.question_text_cy).to eq("Welsh question text from spreadsheet")

        another_page_translation = welsh_translation_input.page_translations.find { |pt| pt.id == another_page.id }
        expect(another_page_translation.page_heading_cy).to eq("Welsh question 2 page heading from spreadsheet")
      end
    end

    context "when the spreadsheet data does not include keys for all fields" do
      let(:spreadsheet_data) do
        {
          "Form name" => "Welsh A form from spreadsheet",
        }
      end

      it "uses the Welsh already set on the form for fields not present in the spreadsheet data" do
        welsh_translation_input = described_class.new(form:)
        welsh_translation_input.assign_from_spreadsheet(spreadsheet_data)

        expect(welsh_translation_input.name_cy).to eq("Welsh A form from spreadsheet")
        expect(welsh_translation_input.support_email_cy).to eq("welsh-support@example.gov.uk")
      end
    end

    context "when the spreadsheet data includes blank values" do
      let(:spreadsheet_data) do
        {
          "Form name" => "Welsh A form from spreadsheet",
          "Contact details for support - email address" => "",
        }
      end

      it "uses the Welsh already set on the form for fields with blank values in the spreadsheet data" do
        welsh_translation_input = described_class.new(form:)
        welsh_translation_input.assign_from_spreadsheet(spreadsheet_data)

        expect(welsh_translation_input.name_cy).to eq("Welsh A form from spreadsheet")
        expect(welsh_translation_input.support_email_cy).to eq("welsh-support@example.gov.uk")
      end
    end
  end

  describe "#all_fields_empty?" do
    context "when the welsh translation fields are not empty" do
      let(:form) { build_form }

      it "returns false" do
        expect(welsh_translation_input.all_fields_empty?).to be false
      end
    end

    context "when the welsh translation fields are all empty" do
      let(:form) { build_empty_welsh_form }

      it "returns true" do
        welsh_translation_input = described_class.new(form:)
        expect(welsh_translation_input.all_fields_empty?).to be true
      end
    end
  end

  describe "#blanked?" do
    let(:page_translation) { Forms::WelshPageTranslationInput.new(page:) }
    let(:new_input_data) do
      {
        form:,
        mark_complete:,
        name_cy: "",
        what_happens_next_markdown_cy: "",
        declaration_markdown_cy: "",
        support_email_cy: "",
        support_phone_cy: "",
        support_url_cy: "",
        support_url_text_cy: "",
        privacy_policy_url_cy: "",
        payment_url_cy: "",
        page_translations: [page_translation],
      }
    end

    context "when the welsh translation fields are all blank" do
      it "returns true" do
        expect(welsh_translation_input.blanked?).to be true
      end
    end

    context "when the pages are not all blank" do
      let(:page_translation) { Forms::WelshPageTranslationInput.new(page:, question_text_cy: "Some question text") }

      it "returns false" do
        expect(welsh_translation_input.blanked?).to be false
      end
    end
  end
end
