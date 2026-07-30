require "rails_helper"

RSpec.describe Forms::ContactDetailsInput, type: :model do
  it "has a valid factory" do
    contact_details_input = build :contact_details_input
    expect(contact_details_input).to be_valid
  end

  describe "validations" do
    describe "email" do
      context "when email is ticked" do
        it "is invalid if blank" do
          contact_details_input = build :contact_details_input, email: ""
          expect(contact_details_input).to be_invalid
        end

        it_behaves_like "a field that rejects invalid email addresses" do
          let(:model) { build :contact_details_input }
          let(:attribute) { :email }
        end

        it "is valid if given an email in the correct format and ending in .gov.uk" do
          contact_details_input = build :contact_details_input, email: "something@something.gov.uk"
          expect(contact_details_input).to be_valid
        end

        context "when the email is a non-government email address" do
          let(:form) { create :form, :with_group }
          let(:contact_details_input) { build :contact_details_input, email: "something@non-departmental.example", form: form }

          it "is invalid" do
            expect(contact_details_input).to be_invalid
            expect(contact_details_input.errors).to be_added :email, :non_government_email
          end

          context "and the organisation has an associated domain matching the email" do
            before do
              create :organisation_domain, organisation: form.group.organisation, domain: "non-departmental.example"
            end

            it "is valid" do
              expect(contact_details_input).to be_valid
            end
          end
        end
      end

      context "when email is not ticked" do
        it "is valid even given an invalid email" do
          contact_details_input = build :contact_details_input, email: "invalid email value", contact_details_supplied: %w[supply_phone supply_link]
          expect(contact_details_input).to be_valid
        end
      end
    end

    describe "phone" do
      context "when phone is ticked" do
        it "is invalid if blank" do
          contact_details_input = build :contact_details_input, phone: ""
          expect(contact_details_input).to be_invalid
        end

        it "is valid if 500 characters" do
          contact_details_input = build :contact_details_input, phone: "x" * 500
          expect(contact_details_input).to be_valid
        end

        it "is invalid if 501 characters" do
          error_message = I18n.t("activemodel.errors.models.forms/contact_details_input.attributes.phone.too_long")
          contact_details_input = build :contact_details_input, phone: "x" * 501
          expect(contact_details_input).to be_invalid
          expect(contact_details_input.errors.full_messages_for(:phone)).to include "Phone #{error_message}"
        end
      end

      context "when phone is not ticked" do
        it "is valid even given invalid phone value" do
          contact_details_input = build :contact_details_input, phone: "", contact_details_supplied: %w[supply_email supply_link]
          expect(contact_details_input).to be_valid
        end
      end
    end

    describe "link" do
      context "when link is ticked" do
        describe "link_text" do
          it "link_text is invalid if blank" do
            error_message = I18n.t("activemodel.errors.models.forms/contact_details_input.attributes.link_text.blank")
            contact_details_input = build :contact_details_input, link_text: ""
            expect(contact_details_input).to be_invalid
            expect(contact_details_input.errors.full_messages_for(:link_text)).to include "Link text #{error_message}"
          end

          it "link_text is valid if 120 characters" do
            contact_details_input = build :contact_details_input, link_text: "https://example.org/".ljust(120, "x")
            expect(contact_details_input).to be_valid
          end

          it "link_text is invalid if 121 characters" do
            error_message = I18n.t("activemodel.errors.models.forms/contact_details_input.attributes.link_text.too_long")
            contact_details_input = build :contact_details_input, link_text: "https://example.org/".ljust(121, "x")
            expect(contact_details_input).to be_invalid
            expect(contact_details_input.errors.full_messages_for(:link_text)).to include "Link text #{error_message}"
          end
        end

        describe "link_href" do
          it "link_href is invalid if blank" do
            error_message = I18n.t("activemodel.errors.models.forms/contact_details_input.attributes.link_href.blank")
            contact_details_input = build :contact_details_input, link_href: ""
            expect(contact_details_input).to be_invalid
            expect(contact_details_input.errors.full_messages_for(:link_href)).to include "Link href #{error_message}"
          end

          it "link_href is valid if 500 characters" do
            contact_details_input = build :contact_details_input, link_href: "https://example.org/".ljust(500, "x")
            expect(contact_details_input).to be_valid
          end

          it "link_href is invalid if 501 characters" do
            error_message = I18n.t("activemodel.errors.models.forms/contact_details_input.attributes.link_href.too_long")
            contact_details_input = build :contact_details_input, link_href: "https://example.org/".ljust(501, "x")
            expect(contact_details_input).to be_invalid
            expect(contact_details_input.errors.full_messages_for(:link_href)).to include "Link href #{error_message}"
          end

          it "link_href is invalid if not a URL" do
            error_message = I18n.t("activemodel.errors.models.forms/contact_details_input.attributes.link_href.url")
            contact_details_input = build :contact_details_input, link_href: "not-url"
            expect(contact_details_input).to be_invalid
            expect(contact_details_input.errors.full_messages_for(:link_href)).to include "Link href #{error_message}"
          end

          it "link_href is valid if a URL" do
            contact_details_input = build :contact_details_input, link_href: "http://tests.org"
            expect(contact_details_input).to be_valid
          end
        end
      end

      context "when link is not ticked" do
        it "is valid even when link_text is invalid" do
          contact_details_input = build :contact_details_input, link_text: "", contact_details_supplied: %w[supply_email supply_phone]
          expect(contact_details_input).to be_valid
        end

        it "is valid even when link_href is invalid" do
          contact_details_input = build :contact_details_input, link_href: "", contact_details_supplied: %w[supply_email supply_phone]
          expect(contact_details_input).to be_valid
        end
      end
    end

    context "when nothing is ticked" do
      it "is valid if form is in draft" do
        contact_details_input = build :contact_details_input, contact_details_supplied: []
        expect(contact_details_input).to be_valid
      end
    end
  end

  describe "#assign_form_values" do
    context "with all support details set" do
      subject(:contact_details_input) { described_class.new(form:) }

      let(:form) { create :form, :with_support }

      before do
        contact_details_input.assign_form_values
      end

      it "assigns email" do
        expect(contact_details_input.email).to eq(form.support_email)
      end

      it "assigns phone" do
        expect(contact_details_input.phone).to eq(form.support_phone)
      end

      it "assigns link_href" do
        expect(contact_details_input.link_href).to eq(form.support_url)
      end

      it "assigns link_text" do
        expect(contact_details_input.link_text).to eq(form.support_url_text)
      end

      it "returns self" do
        expect(contact_details_input.assign_form_values).to eq(contact_details_input)
      end

      it "contact_details_supplied contains correct values" do
        expect(contact_details_input.contact_details_supplied).to include(:supply_email)
      end
    end

    context "without support_email" do
      it "contact_details_supplied contains correct values" do
        form = create :form, :with_support, support_email: ""
        contact_details_input = described_class.new(form:)
        expect(contact_details_input.contact_details_supplied).not_to include(:supply_email)
      end
    end

    context "without support_phone" do
      it "contact_details_supplied does not contains supply_email" do
        form = create :form, :with_support, support_phone: ""
        contact_details_input = described_class.new(form:)
        expect(contact_details_input.contact_details_supplied).not_to include(:supply_email)
      end
    end

    context "without support_url" do
      it "contact_details_supplied contains correct values" do
        form = create :form, :with_support, support_url: ""
        contact_details_input = described_class.new(form:)
        expect(contact_details_input.contact_details_supplied).not_to include(:supply_link)
      end
    end
  end

  describe "#submit" do
    let(:form) { create :form }

    context "when invalid" do
      subject(:contact_details_input) { build :contact_details_input, form:, contact_details_supplied: [:supply_email], email: "invalid_email" }

      it "returns false" do
        expect(contact_details_input.submit).to be false
      end

      it "does not save form" do
        expect {
          contact_details_input.submit
        }.not_to(change { form.reload.support_email })
      end
    end

    context "when valid" do
      subject(:contact_details_input) { build :contact_details_input, form: }

      it "not be false" do
        expect(contact_details_input.submit).to be(true)
      end

      it "saves the form" do
        expect {
          contact_details_input.submit
        }.to change { form.reload.support_email }.to(contact_details_input.email)
      end

      it "sets the form values" do
        form.reload
        contact_details_input.submit
        expect(form.support_email).to eq(contact_details_input.email)
        expect(form.support_phone).to eq(contact_details_input.phone)
        expect(form.support_url).to eq(contact_details_input.link_href)
        expect(form.support_url_text).to eq(contact_details_input.link_text)
      end
    end
  end
end
