require "rails_helper"

RSpec.describe Forms::SubmissionEmailInput, type: :model do
  let(:form) { create :form, submission_email: "curent_value@gds.gov.uk" }

  let(:submission_email_input_with_user) do
    build :submission_email_input, :with_user,
          form:,
          temporary_submission_email: "test@test.gov.uk",
          confirmation_code: "123456",
          current_user: OpenStruct.new(name: "User", email: "user@gov.uk")
  end

  it "has a valid factory" do
    submission_email_input = build :submission_email_input
    expect(submission_email_input).to be_valid
  end

  describe "validations" do
    it "is valid if given an email address ending with .gov.uk" do
      submission_email_input = build :submission_email_input, temporary_submission_email: "a@example.gov.uk"
      expect(submission_email_input).to be_valid
    end

    context "when the user has an email address in an email domain not ending with .gov.uk" do
      before do
        submission_email_input_with_user.current_user = OpenStruct.new(
          name: "Arms Length Body User",
          email: "user@alb.example",
        )
      end

      it "is valid if given an email address in the same domain as the user" do
        submission_email_input_with_user.temporary_submission_email = "submissions@alb.example"
        expect(submission_email_input_with_user).to be_valid
      end
    end

    it "is invalid if given an email address for a non-government inbox" do
      submission_email_input = build :submission_email_input, temporary_submission_email: "a@gmail.com"
      expect(submission_email_input).to be_invalid
    end

    it "is invalid if not given an email address" do
      submission_email_input = build :submission_email_input, temporary_submission_email: nil
      expect(submission_email_input).to be_invalid
    end

    it "is invalid if email_code is in the wrong format" do
      submission_email_input = build :submission_email_input, email_code: "abcdef", confirmation_code: "abcdef"
      expect(submission_email_input).to be_invalid
    end

    it "is invalid if email_code does not match confirmation code" do
      submission_email_input = build :submission_email_input, email_code: "000000", confirmation_code: "123456"
      expect(submission_email_input).to be_invalid
    end
  end

  describe "#assign_form_values" do
    context "when FormSubmissionEmail does not exist for form" do
      it "sets temporary_submission_email to form submission_email" do
        submission_email_input = build(:submission_email_input, form:)

        submission_email_input.assign_form_values
        expect(submission_email_input.temporary_submission_email).to eq("curent_value@gds.gov.uk")
      end
    end

    context "when FormSubmissionEmail exists for form" do
      it "sets temporary_submission_email and confirmation_code from model" do
        create :form_submission_email, form_id: form.id, temporary_submission_email: "test@test.gov.uk", confirmation_code: "654321"
        submission_email_input = build(:submission_email_input, form:)

        submission_email_input.assign_form_values
        expect(submission_email_input.temporary_submission_email).to eq("test@test.gov.uk")
        expect(submission_email_input.confirmation_code).to eq("654321")
      end
    end
  end

  describe "#submit" do
    it "returns false if invalid" do
      submission_email_input = build :submission_email_input, temporary_submission_email: ""
      expect(submission_email_input.submit).to be_falsy
    end

    context "when FormSubmissionEmail does not exist for form" do
      it "creates a FormSubmissionEmail object with form_id" do
        delivery = double
        expect(delivery).to receive(:deliver_now).with(no_args)

        allow(submission_email_input_with_user).to receive(:generate_confirmation_code).and_return("123456")

        allow(SubmissionEmailMailer).to receive(:send_confirmation_code)
                                          .with(
                                            new_submission_email: submission_email_input_with_user.temporary_submission_email,
                                            form_name: form.name,
                                            confirmation_code: submission_email_input_with_user.confirmation_code,
                                            notify_response_id: submission_email_input_with_user.notify_response_id,
                                            current_user: submission_email_input_with_user.current_user,
                                          ).and_return(delivery)

        result = submission_email_input_with_user.submit
        expect(result).to be_truthy
        form_submission_email = FormSubmissionEmail.find_by_form_id(form.id)
        expect(form_submission_email).to be_present
        expect(form_submission_email.temporary_submission_email).to eq("test@test.gov.uk")
        expect(form_submission_email.confirmation_code).not_to be_nil
        expect(form_submission_email.created_by_name).to eq("User")
        expect(form_submission_email.created_by_email).to eq("user@gov.uk")
      end
    end

    context "when FormSubmissionEmail does exist for form" do
      it "updates a FormSubmissionEmail object with form_id" do
        create :form_submission_email, form_id: form.id

        delivery = double
        expect(delivery).to receive(:deliver_now).with(no_args)

        allow(submission_email_input_with_user).to receive(:generate_confirmation_code).and_return("123456")

        allow(SubmissionEmailMailer).to receive(:send_confirmation_code)
                                          .with(
                                            new_submission_email: submission_email_input_with_user.temporary_submission_email,
                                            form_name: form.name,
                                            confirmation_code: submission_email_input_with_user.confirmation_code,
                                            notify_response_id: submission_email_input_with_user.notify_response_id,
                                            current_user: submission_email_input_with_user.current_user,
                                          ).and_return(delivery)

        result = submission_email_input_with_user.submit
        expect(result).to be_truthy
        form_submission_email = FormSubmissionEmail.find_by_form_id(form.id)
        expect(form_submission_email).to be_present
        expect(form_submission_email.temporary_submission_email).to eq("test@test.gov.uk")
        expect(form_submission_email.confirmation_code).not_to be_nil
        expect(form_submission_email.updated_by_name).to eq("User")
        expect(form_submission_email.updated_by_email).to eq("user@gov.uk")
      end
    end
  end

  describe "#confirm_confirmation_code" do
    it "returns false if invalid" do
      submission_email_input = build :submission_email_input, temporary_submission_email: ""
      expect(submission_email_input.confirm_confirmation_code).to be_falsy
    end

    context "when the confirmation code does not match" do
      before do
        create :form_submission_email, form_id: form.id, confirmation_code: "654321"
        submission_email_input_with_user.assign_form_values
      end

      it "returns false" do
        expect(submission_email_input_with_user.confirm_confirmation_code).to be_falsy
      end

      it "does not update the form's submission email" do
        expect {
          submission_email_input_with_user.confirm_confirmation_code
        }.not_to(change(form, :submission_email))
      end

      it "does not create a DeliveryConfiguration" do
        expect {
          submission_email_input_with_user.confirm_confirmation_code
        }.not_to(change { form.delivery_configurations.count })
      end
    end

    context "when the confirmation code matches" do
      before do
        create :form_submission_email, form_id: form.id, confirmation_code: "123456", temporary_submission_email: "test@test.gov.uk"

        submission_email_input_with_user.assign_form_values
      end

      it "returns true" do
        expect(submission_email_input_with_user.confirm_confirmation_code).to be_truthy
      end

      it "updates the form's submission email" do
        expect {
          submission_email_input_with_user.confirm_confirmation_code
        }.to change(form, :submission_email).to "test@test.gov.uk"
      end

      it "marks the FormSubmissionEmail as confirmed" do
        submission_email_input_with_user.confirm_confirmation_code

        form_submission_email = FormSubmissionEmail.find_by_form_id(form.id)
        expect(form_submission_email.confirmation_code).to be_nil
        expect(form_submission_email.updated_by_name).not_to be_nil
        expect(form_submission_email.updated_by_email).not_to be_nil
      end

      context "when a DeliveryConfiguration does not exist for delivery_method: 'email', delivery_schedule: 'immediate'" do
        before do
          # create some DeliveryConfigurations with different delivery_method/delivery_schedule
          create(:delivery_configuration, :daily_email, form:)
          create(:delivery_configuration, :s3, form:)
          form.reload.save!
        end

        it "creates a DeliveryConfiguration" do
          expect {
            submission_email_input_with_user.confirm_confirmation_code
          }.to change { form.delivery_configurations.count }.by(1)

          delivery_configuration = form.delivery_configurations.last
          expect(delivery_configuration).to have_attributes(
            delivery_method: "email",
            delivery_schedule: "immediate",
            formats: [],
          )
        end

        it "updates the form's draft_form_document content with the new DeliveryConfiguration" do
          submission_email_input_with_user.confirm_confirmation_code

          expect(form.draft_form_document.reload.content["delivery_configurations"]).to contain_exactly(
            {
              "delivery_method" => "email",
              "delivery_schedule" => "immediate",
              "formats" => [],
            },
            {
              "delivery_method" => "s3",
              "delivery_schedule" => "immediate",
              "formats" => %w[csv],
            },
            {
              "delivery_method" => "email",
              "delivery_schedule" => "daily",
              "formats" => %w[csv],
            },
          )
        end
      end

      context "when a DeliveryConfiguration already exists for delivery_method: 'email', delivery_schedule: 'immediate'" do
        before do
          create :delivery_configuration, form: form, formats: %w[csv json]
        end

        it "does not create a DeliveryConfiguration" do
          expect {
            submission_email_input_with_user.confirm_confirmation_code
          }.not_to(change { form.delivery_configurations.count })
        end
      end
    end

    context "when FormSubmissionEmail does not exist for form" do
      it "creates a FormSubmissionEmail object with form_id" do
        delivery = double
        expect(delivery).to receive(:deliver_now).with(no_args)

        allow(submission_email_input_with_user).to receive(:generate_confirmation_code).and_return("123456")

        allow(SubmissionEmailMailer).to receive(:send_confirmation_code)
                                          .with(
                                            new_submission_email: submission_email_input_with_user.temporary_submission_email,
                                            form_name: form.name,
                                            confirmation_code: submission_email_input_with_user.confirmation_code,
                                            notify_response_id: submission_email_input_with_user.notify_response_id,
                                            current_user: submission_email_input_with_user.current_user,
                                          ).and_return(delivery)

        result = submission_email_input_with_user.submit
        expect(result).to be_truthy
        form_submission_email = FormSubmissionEmail.find_by_form_id(form.id)
        expect(form_submission_email).to be_present
        expect(form_submission_email.temporary_submission_email).to eq("test@test.gov.uk")
        expect(form_submission_email.confirmation_code).not_to be_nil
        expect(form_submission_email.created_by_name).to eq("User")
        expect(form_submission_email.created_by_email).to eq("user@gov.uk")
      end
    end

    context "when FormSubmissionEmail does exist for form" do
      it "updates a FormSubmissionEmail object with form_id" do
        create :form_submission_email, form_id: form.id
        delivery = double
        expect(delivery).to receive(:deliver_now).with(no_args)

        allow(submission_email_input_with_user).to receive(:generate_confirmation_code).and_return("123456")

        allow(SubmissionEmailMailer).to receive(:send_confirmation_code)
                                          .with(
                                            new_submission_email: submission_email_input_with_user.temporary_submission_email,
                                            form_name: form.name,
                                            confirmation_code: submission_email_input_with_user.confirmation_code,
                                            notify_response_id: submission_email_input_with_user.notify_response_id,
                                            current_user: submission_email_input_with_user.current_user,
                                          ).and_return(delivery)

        result = submission_email_input_with_user.submit
        expect(result).to be_truthy
        form_submission_email = FormSubmissionEmail.find_by_form_id(form.id)
        expect(form_submission_email).to be_present
        expect(form_submission_email.temporary_submission_email).to eq("test@test.gov.uk")
        expect(form_submission_email.confirmation_code).not_to be_nil
        expect(form_submission_email.updated_by_name).to eq("User")
        expect(form_submission_email.updated_by_email).to eq("user@gov.uk")
      end
    end
  end
end
