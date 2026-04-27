require "rails_helper"

describe AdminAlerts::GroupFormsMoveMailer, type: :mailer do
  let(:current_user) { create :organisation_admin_user }
  let(:group) { create :group }
  let(:old_group) { create :group }
  let(:form) { create :form, name: "Form name" }
  let(:to_email) { "email@example.gov.uk" }

  describe "#form_move_email" do
    context "when user is an org admin" do
      subject(:mail) do
        described_class.form_moved_email_org_admin(
          to_email:,
          form_name: form.name,
          old_group_name: old_group.name,
          new_group_name: group.name,
          org_admin_email: current_user.email,
          org_admin_name: current_user.name,
          group_active: group.active?,
        )
      end

      it "sends an email with the correct template" do
        expect(mail.govuk_notify_template).to eq(Settings.govuk_notify.admin_alerts.group_form_moved_org_admin_template_id)
      end

      it "includes the personalisation" do
        expect(mail.govuk_notify_personalisation[:form_name]).to eq(form.name)
        expect(mail.govuk_notify_personalisation[:old_group_name]).to eq(old_group.name)
        expect(mail.govuk_notify_personalisation[:new_group_name]).to eq(group.name)
        expect(mail.govuk_notify_personalisation[:org_admin_email]).to eq(current_user.email)
        expect(mail.govuk_notify_personalisation[:org_admin_name]).to eq(current_user.name)
        expect(mail.govuk_notify_personalisation[:group_active]).to eq("no")
        expect(mail.govuk_notify_personalisation[:group_trial]).to eq("yes")
      end

      context "when group is active" do
        let(:group) { create :group, status: :active }

        it "personalisation includes group active as yes instead of trial" do
          expect(mail.govuk_notify_personalisation[:group_active]).to eq("yes")
          expect(mail.govuk_notify_personalisation[:group_trial]).to eq("no")
        end
      end
    end

    context "when users is a group admin" do
      subject(:mail) do
        described_class.form_moved_email_group_admin(
          to_email:,
          form_name: form.name,
          old_group_name: old_group.name,
          new_group_name: group.name,
          org_admin_email: current_user.email,
          org_admin_name: current_user.name,
          group_active: group.active?,
        )
      end

      it "sends an email with the correct template" do
        expect(mail.govuk_notify_template).to eq(Settings.govuk_notify.admin_alerts.group_form_moved_group_admin_editor_template_id)
      end

      it "includes the personalisation" do
        expect(mail.govuk_notify_personalisation[:form_name]).to eq(form.name)
        expect(mail.govuk_notify_personalisation[:old_group_name]).to eq(old_group.name)
        expect(mail.govuk_notify_personalisation[:new_group_name]).to eq(group.name)
        expect(mail.govuk_notify_personalisation[:org_admin_email]).to eq(current_user.email)
        expect(mail.govuk_notify_personalisation[:org_admin_name]).to eq(current_user.name)
        expect(mail.govuk_notify_personalisation[:group_active]).to eq("no")
        expect(mail.govuk_notify_personalisation[:group_trial]).to eq("yes")
      end
    end
  end
end
