require "rails_helper"

describe AdminAlerts::DraftCreatedMailer, type: :mailer do
  let(:form) { create :form, :with_group }
  let(:user) { create :user }
  let(:to_email) { "admin@example.gov.uk" }

  describe "#new_draft_form_created" do
    subject(:mail) do
      described_class.new_draft_form_created(form:, user:, to_email:)
    end

    it "sends an email with the correct template" do
      expect(mail.govuk_notify_template).to eq(Settings.govuk_notify.admin_alerts.new_draft_form_created_template_id)
    end

    it "sends an email to the correct email address" do
      expect(mail.to).to eq([to_email])
    end

    it "includes the personalisation" do
      expect(mail.govuk_notify_personalisation[:form_name]).to eq(form.name)
      expect(mail.govuk_notify_personalisation[:form_link]).to eq(form_url(form))
      expect(mail.govuk_notify_personalisation[:group_name]).to eq(form.group.name)
      expect(mail.govuk_notify_personalisation[:user_name]).to eq(user.name)
      expect(mail.govuk_notify_personalisation[:user_email]).to eq(user.email)
    end
  end

  describe "#copied_draft_form_created" do
    subject(:mail) do
      described_class.copied_draft_form_created(form:, copied_from_form:, user:, to_email:)
    end

    let(:copied_from_form) { create :form }

    it "sends an email with the correct template" do
      expect(mail.govuk_notify_template).to eq(Settings.govuk_notify.admin_alerts.copied_draft_form_created_template_id)
    end

    it "sends an email to the correct email address" do
      expect(mail.to).to eq([to_email])
    end

    it "includes the personalisation" do
      expect(mail.govuk_notify_personalisation[:form_name]).to eq(form.name)
      expect(mail.govuk_notify_personalisation[:form_link]).to eq(form_url(form))
      expect(mail.govuk_notify_personalisation[:copied_from_form_name]).to eq(copied_from_form.name)
      expect(mail.govuk_notify_personalisation[:copied_from_form_link]).to eq(form_url(copied_from_form))
      expect(mail.govuk_notify_personalisation[:group_name]).to eq(form.group.name)
      expect(mail.govuk_notify_personalisation[:user_name]).to eq(user.name)
      expect(mail.govuk_notify_personalisation[:user_email]).to eq(user.email)
    end
  end

  describe "#new_archived_form_draft_created" do
    subject(:mail) do
      described_class.new_archived_form_draft_created(form: archived_form, user:, to_email:)
    end

    let(:archived_form) { create :form, :archived_with_draft, :with_group }
    let(:new_draft_name) { "New Draft Form Name" }

    before do
      archived_form.name = new_draft_name
      archived_form.save!
    end

    it "sends an email with the correct template" do
      expect(mail.govuk_notify_template).to eq(Settings.govuk_notify.admin_alerts.new_archived_form_draft_created_template_id)
    end

    it "sends an email to the correct email address" do
      expect(mail.to).to eq([to_email])
    end

    it "includes the personalisation" do
      expect(mail.govuk_notify_personalisation[:form_name]).to eq(new_draft_name)
      expect(mail.govuk_notify_personalisation[:form_link]).to eq(form_url(archived_form))
      expect(mail.govuk_notify_personalisation[:archived_form_name]).to eq(archived_form.latest_form_document.content["name"])
      expect(mail.govuk_notify_personalisation[:archived_form_link]).to eq(archived_form_url(archived_form))
      expect(mail.govuk_notify_personalisation[:group_name]).to eq(archived_form.group.name)
      expect(mail.govuk_notify_personalisation[:user_name]).to eq(user.name)
      expect(mail.govuk_notify_personalisation[:user_email]).to eq(user.email)
    end
  end

  describe "#new_live_form_draft_created" do
    subject(:mail) do
      described_class.new_live_form_draft_created(form: live_form, user:, to_email:)
    end

    let(:live_form) { create :form, :live_with_draft, :with_group }
    let(:new_draft_name) { "New Draft Form Name" }

    before do
      live_form.name = new_draft_name
      live_form.save!
    end

    it "sends an email with the correct template" do
      expect(mail.govuk_notify_template).to eq(Settings.govuk_notify.admin_alerts.new_live_form_draft_created_template_id)
    end

    it "sends an email to the correct email address" do
      expect(mail.to).to eq([to_email])
    end

    it "includes the personalisation" do
      expect(mail.govuk_notify_personalisation[:form_name]).to eq(new_draft_name)
      expect(mail.govuk_notify_personalisation[:form_link]).to eq(form_url(live_form))
      expect(mail.govuk_notify_personalisation[:live_form_name]).to eq(live_form.latest_form_document.content["name"])
      expect(mail.govuk_notify_personalisation[:live_form_link]).to eq(live_form_url(live_form))
      expect(mail.govuk_notify_personalisation[:group_name]).to eq(live_form.group.name)
      expect(mail.govuk_notify_personalisation[:user_name]).to eq(user.name)
      expect(mail.govuk_notify_personalisation[:user_email]).to eq(user.email)
    end
  end
end
