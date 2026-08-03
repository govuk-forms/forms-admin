require "rails_helper"

RSpec.describe Forms::SubmissionEmailController, type: :request do
  include ActionView::Helpers::TextHelper

  let(:organisation) { build :organisation, slug: "test-org" }
  let(:user) { standard_user }
  let(:user_outside_group) { build :user, id: 2, organisation: }

  let(:form) { create :form, creator_id: 1 }

  let(:submission_email_mailer_spy) do
    submission_email_mailer = instance_spy(SubmissionEmailMailer)
    allow(SubmissionEmailMailer).to receive(:new).and_return(submission_email_mailer)
    submission_email_mailer
  end

  let(:group) { create(:group, organisation: standard_user.organisation) }

  before do
    Membership.create!(group_id: group.id, user: standard_user, added_by: standard_user)
    GroupForm.create!(form_id: form.id, group_id: group.id)

    login_as user
  end

  describe "#new" do
    before do
      get submission_email_input_path(form.id)
    end

    it "returns HTTP code 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the correct page" do
      expect(response).to render_template(:new)
    end

    context "when current user does not belong to the group" do
      let(:user) { user_outside_group }

      it "is forbidden" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "#create" do
    let(:temporary_submission_email) { user.email }
    let(:params) do
      {
        forms_submission_email_input: {
          temporary_submission_email:,
          notify_response_id: Faker::Internet.uuid,
        },
      }
    end

    before do
      allow(submission_email_mailer_spy).to receive(:send_confirmation_code)
    end

    it "redirects to the email code sent page" do
      post(submission_email_path(form.id), params: params)
      expect(response).to redirect_to(submission_email_code_sent_path(form.id))
    end

    context "when user submits a non-government email address" do
      let(:domain) { "ogd.example" }
      let(:temporary_submission_email) { Faker::Internet.email(domain:) }

      it "does not accept the submission email address" do
        post(submission_email_path(form.id), params: params)
        expect(response.body).to include I18n.t("error_summary.heading")
        expect(response.body).to include I18n.t("errors.messages.non_government_email")
        expect(response).to have_http_status :unprocessable_content
      end

      context "and the organisation has an associated domain matching the email" do
        before do
          create :organisation_domain, organisation: group.organisation, domain: domain
        end

        it "redirects to the email code sent page" do
          post(submission_email_path(form.id), params: params)
          expect(response).to redirect_to(submission_email_code_sent_path(form.id))
        end
      end
    end

    context "when current user does not belong to group" do
      let(:user) { user_outside_group }

      it "is forbidden" do
        post(submission_email_path(form.id), params: params)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "#submission_email_code_sent" do
    before do
      get submission_email_code_sent_path(form.id)
    end

    it "returns HTTP code 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the correct page" do
      expect(response).to render_template(:submission_email_code_sent)
    end

    context "when current user does not belong to the group" do
      let(:user) { user_outside_group }

      it "is forbidden" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "#submission_email_code" do
    before do
      get submission_email_code_path(form.id)
    end

    it "returns HTTP code 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the correct page" do
      expect(response).to render_template(:submission_email_code)
    end

    context "when current user does not belong to the group" do
      let(:user) { user_outside_group }

      it "is forbidden" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "#confirm_submission_email_code" do
    let(:confirmation_code) { "123456" }
    let(:submitted_code) { confirmation_code }

    before do
      allow(FormSubmissionEmail).to receive(:find_by_form_id).and_return(build(
                                                                           :form_submission_email,
                                                                           form_id: 1,
                                                                           temporary_submission_email: user.email,
                                                                           confirmation_code:,
                                                                         ))

      post(
        confirm_submission_email_code_path(form.id),
        params: {
          forms_submission_email_input: {
            email_code: submitted_code,
          },
        },
      )
    end

    it "redirects to the confirmation page" do
      expect(response).to redirect_to(submission_email_confirmed_path(form.id))
    end

    context "when user submits the wrong confirmation code" do
      let(:submitted_code) { "123455" }

      it "responds with an error" do
        expect(response.body).to include I18n.t("error_summary.heading")
        expect(response).to have_http_status :unprocessable_content
      end
    end

    context "when current user does not belong to the group" do
      let(:user) { user_outside_group }

      it "is forbidden" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "#submission_email_confirmed" do
    context "when the form is not live" do
      before do
        get submission_email_confirmed_path(form.id)
      end

      it "returns HTTP code 200" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the correct page" do
        expect(response).to render_template(:submission_email_confirmed)
      end

      it "displays the default confirmation text" do
        expect(response.body).to include(I18n.t("email_code_success.body_html", submission_email: form.submission_email))
      end

      context "when current user does not belong to the group" do
        let(:user) { user_outside_group }

        it "is forbidden" do
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context "when the form is live" do
      let(:form) { create :form, :live, creator_id: 1 }

      context "when the email address is the same as for the live version" do
        before do
          get submission_email_confirmed_path(form.id)
        end

        it "displays the default confirmation text" do
          expect(response.body).to include(I18n.t("email_code_success.body_html", submission_email: form.submission_email))
        end
      end

      context "when draft version submission email is different from live version" do
        before do
          form.submission_email = Faker::Internet.email(domain: "different.gov.uk")
          form.save!

          get submission_email_confirmed_path(form.id)
        end

        it "displays the confirmation text for when the email has changed" do
          expect(response.body).to include(simple_format(I18n.t("email_code_success.live_submission_email_changed_body_html", new_submission_email: form.submission_email)))
        end
      end
    end
  end
end
