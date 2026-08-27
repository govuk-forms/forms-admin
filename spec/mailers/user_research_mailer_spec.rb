require "rails_helper"

describe UserResearchMailer, type: :mailer do
  describe "#invitation_email" do
    subject(:mail) { described_class.invitation_email(user) }

    let(:user) { create(:user) }

    it "sends an email with the correct template" do
      expect(mail.govuk_notify_template).to eq(Settings.govuk_notify.user_research_invitation_template_id)
    end

    it "sends an email to the user" do
      expect(mail.to).to eq([user.email])
    end

    it "includes the user's name" do
      expect(mail.govuk_notify_personalisation[:name]).to eq(user.name)
    end
  end
end
