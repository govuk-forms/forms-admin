require "rails_helper"

describe Account::ContactForResearchInput do
  include ActiveSupport::Testing::TimeHelpers

  subject(:contact_for_research_input) { described_class.new(user:) }

  let(:user) { create(:user) }

  describe "#submit" do
    let(:delivery) { double }

    before do
      allow(UserResearchMailer).to receive(:invitation_email).and_return(delivery)
      allow(delivery).to receive(:deliver_now).with(no_args)
    end

    context "with valid attributes" do
      before do
        contact_for_research_input.research_contact_status = "consented"
      end

      it "updates the user research opted in at timestamp" do
        current_time = Time.zone.now.midnight
        travel_to current_time

        expect { contact_for_research_input.submit }.to change { user.reload.user_research_opted_in_at }.to(current_time)
      end

      it "returns true" do
        expect(contact_for_research_input.submit).to be true
      end
    end

    context "when the user consents" do
      before do
        contact_for_research_input.research_contact_status = "consented"
      end

      it "sends the invitation email" do
        contact_for_research_input.submit
        expect(UserResearchMailer).to have_received(:invitation_email).with(user)
        expect(delivery).to have_received(:deliver_now)
      end

      context "when sending the email fails" do
        let(:error) { StandardError.new("Notify is down") }

        before do
          allow(delivery).to receive(:deliver_now).and_raise(error)
          allow(Sentry).to receive(:capture_exception)
        end

        it "still returns true and reports the error to Sentry" do
          expect(contact_for_research_input.submit).to be true
          expect(Sentry).to have_received(:capture_exception).with(error)
        end
      end
    end

    context "when the user declines" do
      before do
        contact_for_research_input.research_contact_status = "declined"
      end

      it "does not send the invitation email" do
        contact_for_research_input.submit
        expect(UserResearchMailer).not_to have_received(:invitation_email)
      end
    end

    context "when the user has already consented" do
      let(:user) { create(:user, research_contact_status: "consented") }

      before do
        contact_for_research_input.research_contact_status = "consented"
      end

      it "does not send the invitation email again" do
        contact_for_research_input.submit
        expect(UserResearchMailer).not_to have_received(:invitation_email)
      end
    end
  end
end
