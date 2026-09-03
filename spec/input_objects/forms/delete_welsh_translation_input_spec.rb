require "rails_helper"

RSpec.describe Forms::DeleteWelshTranslationInput, type: :model do
  subject(:delete_welsh_translation_input) { described_class.new(confirm:, form:) }

  let(:confirm) { nil }

  let(:form) { nil }

  describe "validations" do
    describe "confirm" do
      context "when user selects 'yes'" do
        let(:confirm) { "yes" }

        it { is_expected.to be_valid }
      end

      context "when user selects 'no'" do
        let(:confirm) { "no" }

        it { is_expected.to be_valid }
      end

      context "when user does not select an option" do
        it "is invalid" do
          error_message = I18n.t("activemodel.errors.models.forms/delete_welsh_translation_input.attributes.confirm.blank")

          expect(delete_welsh_translation_input).not_to be_valid

          expect(delete_welsh_translation_input.errors.full_messages_for(:confirm)).to include(
            "Confirm #{error_message}",
          )
        end
      end
    end
  end

  describe "#submit" do
    let(:form) do
      create :form,
             name_cy: "New Welsh name",
             what_happens_next_markdown: "English what happens next",
             what_happens_next_markdown_cy: "New Welsh what happens next",
             declaration_markdown: "English declaration",
             declaration_markdown_cy: "New Welsh declaration",
             support_email: "english-support@example.gov.uk",
             support_email_cy: "new-welsh-support@example.gov.uk",
             support_phone: "English support phone",
             support_phone_cy: "0800 123 4567",
             support_url: "https://www.gov.uk/english-support",
             support_url_cy: "https://www.gov.uk/new-welsh-support",
             support_url_text: "English support url text",
             support_url_text_cy: "New Welsh Support",
             privacy_policy_url: "https://www.gov.uk/english-privacy",
             privacy_policy_url_cy: "https://www.gov.uk/new-welsh-privacy",
             payment_url_cy: "https://www.gov.uk/payments/new-welsh-payment-link",
             available_languages: %w[en cy],
             welsh_completed: true,
             pages: [page]
    end

    let(:page) do
      create :page,
             question_text_cy: "Ydych chi'n adnewyddu trwydded?",
             hint_text: "English hint text",
             hint_text_cy: "Dewiswch 'Ydw' os oes gennych drwydded ddilys eisoes.",
             page_heading: "English page heading",
             page_heading_cy: "Trwyddedu",
             guidance_markdown: "English guidance",
             guidance_markdown_cy: "Mae'r rhan hon o'r ffurflen yn ymwneud â thrwyddedu.",
             answer_settings_cy: {
               selection_options: [
                 { name: "Welsh option 1", value: "Option 1" },
                 { name: "Welsh option 2", value: "Option 2" },
               ],
               none_of_the_above_question: {
                 question_text: "Welsh none of the above question?",
               },
             }
    end

    let(:condition) do
      create :condition,
             routing_page: page,
             exit_page_markdown_cy: "Nid ydych yn gymwys",
             exit_page_heading_cy: "Mae'n ddrwg gennym, nid ydych yn gymwys ar gyfer y gwasanaeth hwn."
    end

    let(:exit_page) do
      create :exit_page,
             question_page: page,
             markdown_cy: "Nid ydych yn gymwys",
             heading_cy: "Mae'n ddrwg gennym, nid ydych yn gymwys ar gyfer y gwasanaeth hwn."
    end

    context "when the input is invalid" do
      it "returns false" do
        expect(delete_welsh_translation_input.submit).to be false
      end
    end

    context "when the input is valid" do
      context "when the user has selected 'no'" do
        let(:confirm) { "no" }

        it "returns true" do
          expect(delete_welsh_translation_input.submit).to be true
        end

        it "does not change any of the welsh content" do
          expect { delete_welsh_translation_input.submit }.not_to change(form, :reload)
        end

        it "does not reset the available_languages field" do
          expect { delete_welsh_translation_input.submit }.not_to change(form.reload, :available_languages)
        end

        it "does not reset the welsh_completed status" do
          expect { delete_welsh_translation_input.submit }.not_to change(form.reload, :welsh_completed)
        end
      end

      context "when the user has selected 'yes'" do
        let(:confirm) { "yes" }

        it "returns true" do
          expect(delete_welsh_translation_input.submit).to be true
        end

        it "deletes all of the welsh form content" do
          expect { delete_welsh_translation_input.submit }.to change { form.reload.what_happens_next_markdown_cy }.to(nil)
            .and change { form.reload.declaration_markdown_cy }.to(nil)
            .and change { form.reload.support_email_cy }.to(nil)
            .and change { form.reload.support_phone_cy }.to(nil)
            .and change { form.reload.support_url_cy }.to(nil)
            .and change { form.reload.support_url_text_cy }.to(nil)
            .and change { form.reload.privacy_policy_url_cy }.to(nil)
            .and change { form.reload.payment_url_cy }.to(nil)
        end

        it "deletes all of the welsh page content" do
          expect { delete_welsh_translation_input.submit }.to change { page.reload.question_text_cy }.to(nil)
            .and change { page.reload.hint_text_cy }.to(nil)
            .and change { page.reload.page_heading_cy }.to(nil)
            .and change { page.reload.guidance_markdown_cy }.to(nil)
            .and change { page.reload.answer_settings_cy }.to(nil)
        end

        it "deletes all of the welsh condition content" do
          expect { delete_welsh_translation_input.submit }.to change { condition.reload.exit_page_markdown_cy }.to(nil)
            .and change { condition.reload.exit_page_heading_cy }.to(nil)
        end

        it "deletes all of the welsh exit page content" do
          expect { delete_welsh_translation_input.submit }.to change { exit_page.reload.markdown_cy }.to(nil)
            .and change { exit_page.reload.heading_cy }.to(nil)
        end

        it "resets the available_languages field to only include English" do
          expect { delete_welsh_translation_input.submit }.to change { form.reload.available_languages }.to(%w[en])
        end

        it "resets the welsh_completed status" do
          expect { delete_welsh_translation_input.submit }.to change { form.reload.welsh_completed }.to(false)
        end

        context "when the form is live" do
          let(:form)  do
            create :form,
                   :live,
                   name_cy: "New Welsh name",
                   what_happens_next_markdown: "English what happens next",
                   what_happens_next_markdown_cy: "New Welsh what happens next",
                   declaration_markdown: "English declaration",
                   declaration_markdown_cy: "New Welsh declaration",
                   support_email: "english-support@example.gov.uk",
                   support_email_cy: "new-welsh-support@example.gov.uk",
                   support_phone: "English support phone",
                   support_phone_cy: "0800 123 4567",
                   support_url: "https://www.gov.uk/english-support",
                   support_url_cy: "https://www.gov.uk/new-welsh-support",
                   support_url_text: "English support url text",
                   support_url_text_cy: "New Welsh Support",
                   privacy_policy_url: "https://www.gov.uk/english-privacy",
                   privacy_policy_url_cy: "https://www.gov.uk/new-welsh-privacy",
                   payment_url_cy: "https://www.gov.uk/payments/new-welsh-payment-link",
                   available_languages: %w[en cy],
                   welsh_completed: true,
                   pages: [page]
          end

          it "sets the form_status to `live_with_draft`" do
            expect { delete_welsh_translation_input.submit }.to change { form.reload.state }.to("live_with_draft")
          end
        end

        context "when the form is archived" do
          let(:form)  do
            create :form,
                   :archived,
                   name_cy: "New Welsh name",
                   what_happens_next_markdown: "English what happens next",
                   what_happens_next_markdown_cy: "New Welsh what happens next",
                   declaration_markdown: "English declaration",
                   declaration_markdown_cy: "New Welsh declaration",
                   support_email: "english-support@example.gov.uk",
                   support_email_cy: "new-welsh-support@example.gov.uk",
                   support_phone: "English support phone",
                   support_phone_cy: "0800 123 4567",
                   support_url: "https://www.gov.uk/english-support",
                   support_url_cy: "https://www.gov.uk/new-welsh-support",
                   support_url_text: "English support url text",
                   support_url_text_cy: "New Welsh Support",
                   privacy_policy_url: "https://www.gov.uk/english-privacy",
                   privacy_policy_url_cy: "https://www.gov.uk/new-welsh-privacy",
                   payment_url_cy: "https://www.gov.uk/payments/new-welsh-payment-link",
                   available_languages: %w[en cy],
                   welsh_completed: true,
                   pages: [page]
          end

          it "sets the form_status to `archived_with_draft`" do
            expect { delete_welsh_translation_input.submit }.to change { form.reload.state }.to("archived_with_draft")
          end
        end
      end
    end
  end

  describe "#submit_without_confirm" do
    let(:form) do
      create :form,
             name_cy: "New Welsh name",
             what_happens_next_markdown: "English what happens next",
             what_happens_next_markdown_cy: "New Welsh what happens next",
             declaration_text: "English declaration",
             declaration_text_cy: "New Welsh declaration",
             support_email: "english-support@example.gov.uk",
             support_email_cy: "new-welsh-support@example.gov.uk",
             support_phone: "English support phone",
             support_phone_cy: "0800 123 4567",
             support_url: "https://www.gov.uk/english-support",
             support_url_cy: "https://www.gov.uk/new-welsh-support",
             support_url_text: "English support url text",
             support_url_text_cy: "New Welsh Support",
             privacy_policy_url: "https://www.gov.uk/english-privacy",
             privacy_policy_url_cy: "https://www.gov.uk/new-welsh-privacy",
             payment_url_cy: "https://www.gov.uk/payments/new-welsh-payment-link",
             available_languages: %w[en cy],
             welsh_completed: true,
             pages: [page]
    end

    let(:page) do
      create :page,
             question_text_cy: "Ydych chi'n adnewyddu trwydded?",
             hint_text: "English hint text",
             hint_text_cy: "Dewiswch 'Ydw' os oes gennych drwydded ddilys eisoes.",
             page_heading: "English page heading",
             page_heading_cy: "Trwyddedu",
             guidance_markdown: "English guidance",
             guidance_markdown_cy: "Mae'r rhan hon o'r ffurflen yn ymwneud â thrwyddedu.",
             answer_settings_cy: {
               selection_options: [
                 { name: "Welsh option 1", value: "Option 1" },
                 { name: "Welsh option 2", value: "Option 2" },
               ],
               none_of_the_above_question: {
                 question_text: "Welsh none of the above question?",
               },
             }
    end

    let(:condition) do
      create :condition,
             routing_page: page,
             exit_page_markdown_cy: "Nid ydych yn gymwys",
             exit_page_heading_cy: "Mae'n ddrwg gennym, nid ydych yn gymwys ar gyfer y gwasanaeth hwn."
    end

    let(:exit_page) do
      create :exit_page,
             question_page: page,
             markdown_cy: "Nid ydych yn gymwys",
             heading_cy: "Mae'n ddrwg gennym, nid ydych yn gymwys ar gyfer y gwasanaeth hwn."
    end

    context "when called" do
      it "returns true" do
        expect(delete_welsh_translation_input.submit_without_confirm).to be true
      end

      it "deletes all of the welsh form content" do
        expect { delete_welsh_translation_input.submit_without_confirm }.to change { form.reload.what_happens_next_markdown_cy }.to(nil)
          .and change { form.reload.declaration_text_cy }.to(nil)
          .and change { form.reload.support_email_cy }.to(nil)
          .and change { form.reload.support_phone_cy }.to(nil)
          .and change { form.reload.support_url_cy }.to(nil)
          .and change { form.reload.support_url_text_cy }.to(nil)
          .and change { form.reload.privacy_policy_url_cy }.to(nil)
          .and change { form.reload.payment_url_cy }.to(nil)
      end

      it "deletes all of the welsh page content" do
        expect { delete_welsh_translation_input.submit_without_confirm }.to change { page.reload.question_text_cy }.to(nil)
          .and change { page.reload.hint_text_cy }.to(nil)
          .and change { page.reload.page_heading_cy }.to(nil)
          .and change { page.reload.guidance_markdown_cy }.to(nil)
          .and change { page.reload.answer_settings_cy }.to(nil)
      end

      it "deletes all of the welsh condition content" do
        expect { delete_welsh_translation_input.submit_without_confirm }.to change { condition.reload.exit_page_markdown_cy }.to(nil)
          .and change { condition.reload.exit_page_heading_cy }.to(nil)
      end

      it "deletes all of the welsh exit page content" do
        expect { delete_welsh_translation_input.submit_without_confirm }.to change { exit_page.reload.markdown_cy }.to(nil)
          .and change { exit_page.reload.heading_cy }.to(nil)
      end

      it "resets the available_languages field to only include English" do
        expect { delete_welsh_translation_input.submit_without_confirm }.to change { form.reload.available_languages }.to(%w[en])
      end

      it "resets the welsh_completed status" do
        expect { delete_welsh_translation_input.submit_without_confirm }.to change { form.reload.welsh_completed }.to(false)
      end

      context "when the form is live" do
        let(:form) do
          create :form,
                 :live,
                 name_cy: "New Welsh name",
                 what_happens_next_markdown: "English what happens next",
                 what_happens_next_markdown_cy: "New Welsh what happens next",
                 declaration_text: "English declaration",
                 declaration_text_cy: "New Welsh declaration",
                 support_email: "english-support@example.gov.uk",
                 support_email_cy: "new-welsh-support@example.gov.uk",
                 support_phone: "English support phone",
                 support_phone_cy: "0800 123 4567",
                 support_url: "https://www.gov.uk/english-support",
                 support_url_cy: "https://www.gov.uk/new-welsh-support",
                 support_url_text: "English support url text",
                 support_url_text_cy: "New Welsh Support",
                 privacy_policy_url: "https://www.gov.uk/english-privacy",
                 privacy_policy_url_cy: "https://www.gov.uk/new-welsh-privacy",
                 payment_url_cy: "https://www.gov.uk/payments/new-welsh-payment-link",
                 available_languages: %w[en cy],
                 welsh_completed: true,
                 pages: [page]
        end

        it "sets the form_status to `live_with_draft`" do
          expect { delete_welsh_translation_input.submit_without_confirm }.to change { form.reload.state }.to("live_with_draft")
        end
      end

      context "when the form is archived" do
        let(:form)  do
          create :form,
                 :archived,
                 name_cy: "New Welsh name",
                 what_happens_next_markdown: "English what happens next",
                 what_happens_next_markdown_cy: "New Welsh what happens next",
                 declaration_text: "English declaration",
                 declaration_text_cy: "New Welsh declaration",
                 support_email: "english-support@example.gov.uk",
                 support_email_cy: "new-welsh-support@example.gov.uk",
                 support_phone: "English support phone",
                 support_phone_cy: "0800 123 4567",
                 support_url: "https://www.gov.uk/english-support",
                 support_url_cy: "https://www.gov.uk/new-welsh-support",
                 support_url_text: "English support url text",
                 support_url_text_cy: "New Welsh Support",
                 privacy_policy_url: "https://www.gov.uk/english-privacy",
                 privacy_policy_url_cy: "https://www.gov.uk/new-welsh-privacy",
                 payment_url_cy: "https://www.gov.uk/payments/new-welsh-payment-link",
                 available_languages: %w[en cy],
                 welsh_completed: true,
                 pages: [page]
        end

        it "sets the form_status to `archived_with_draft`" do
          expect { delete_welsh_translation_input.submit_without_confirm }.to change { form.reload.state }.to("archived_with_draft")
        end
      end
    end
  end

  describe "#confirmed?" do
    context "when the input is invalid" do
      it "returns false" do
        expect(delete_welsh_translation_input.confirmed?).to be false
      end
    end

    context "when the input is valid" do
      context "when the user has selected 'no'" do
        let(:confirm) { "no" }

        it "returns false" do
          expect(delete_welsh_translation_input.confirmed?).to be false
        end
      end

      context "when the user has selected 'yes'" do
        let(:confirm) { "yes" }

        it "returns true" do
          expect(delete_welsh_translation_input.confirmed?).to be true
        end
      end
    end
  end
end
