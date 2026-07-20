require "rails_helper"

RSpec.describe GroupService do
  subject(:group_service) do
    described_class.new(group:, current_user:, host:)
  end

  let(:organisation) { create :organisation }
  let(:group) { create :group, organisation: }
  let(:current_user) { create :user, organisation: }
  let(:host) { "example.net" }

  describe "#upgrade_group" do
    let(:first_group_admin_user) { create :user, organisation: }
    let(:second_group_admin_user) { create :user, organisation: }
    let(:editor_user) { create :user, organisation: }
    let(:group) do
      create(:group, organisation:).tap do |group|
        create(:membership, user: first_group_admin_user, group:, role: :group_admin)
        create(:membership, user: second_group_admin_user, group:, role: :group_admin)
        create(:membership, user: editor_user, group:, role: :editor)
        create(:membership, user: current_user, group:, role: :group_admin)
      end
    end
    let(:delivery) { double }

    before do
      allow(GroupUpgradeMailer).to receive(:upgraded_email).and_return(delivery)
      allow(delivery).to receive(:deliver_now).with(no_args)
    end

    it "upgrades the group to active" do
      expect {
        group_service.upgrade_group
      }.to change(group, :status).to("active")
    end

    it "sends an email to all group admins" do
      group_service.upgrade_group
      expect(delivery).to have_received(:deliver_now).with(no_args).exactly(2).times
      expect(GroupUpgradeMailer).to have_received(:upgraded_email).with(
        to_email: first_group_admin_user.email,
        upgraded_by_name: current_user.name,
        group_name: group.name,
        group_url: group_url(group, host:),
      )
      expect(GroupUpgradeMailer).to have_received(:upgraded_email).with(
        to_email: second_group_admin_user.email,
        upgraded_by_name: current_user.name,
        group_name: group.name,
        group_url: group_url(group, host:),
      )
    end

    it "does not send an email to the logged in user that performed the upgrade if they are a group admin" do
      group_service.upgrade_group
      expect(GroupUpgradeMailer).not_to have_received(:upgraded_email).with(
        to_email: current_user.email,
        upgraded_by_name: current_user.name,
        group_name: group.name,
        group_url: group_url(group, host:),
      )
    end
  end

  describe "#reject_upgrade" do
    let(:first_group_admin_user) { create :user, organisation: }
    let(:second_group_admin_user) { create :user, organisation: }
    let(:editor_user) { create :user, organisation: }
    let(:group) do
      create(:group, status: :upgrade_requested, organisation:).tap do |group|
        create(:membership, user: first_group_admin_user, group:, role: :group_admin)
        create(:membership, user: second_group_admin_user, group:, role: :group_admin)
        create(:membership, user: editor_user, group:, role: :editor)
        create(:membership, user: current_user, group:, role: :group_admin)
      end
    end
    let(:delivery) { double }

    before do
      allow(GroupUpgradeMailer).to receive(:rejected_email).and_return(delivery)
      allow(delivery).to receive(:deliver_now).with(no_args)
    end

    it "changes the group status to trial" do
      expect {
        group_service.reject_upgrade
      }.to change(group, :status).to("trial")
    end

    it "sends an email to all group admins" do
      group_service.reject_upgrade
      expect(delivery).to have_received(:deliver_now).with(no_args).exactly(2).times
      expect(GroupUpgradeMailer).to have_received(:rejected_email).with(
        to_email: first_group_admin_user.email,
        rejected_by_name: current_user.name,
        rejected_by_email: current_user.email,
        group_name: group.name,
        group_url: group_url(group, host:),
      )
      expect(GroupUpgradeMailer).to have_received(:rejected_email).with(
        to_email: second_group_admin_user.email,
        rejected_by_name: current_user.name,
        rejected_by_email: current_user.email,
        group_name: group.name,
        group_url: group_url(group, host:),
      )
    end

    it "does not send an email to the logged in user that rejected the upgrade if they are a group admin" do
      group_service.reject_upgrade
      expect(GroupUpgradeMailer).not_to have_received(:rejected_email).with(
        to_email: current_user.email,
        rejected_by_name: current_user.name,
        rejected_by_email: current_user.email,
        group_name: group.name,
        group_url: group_url(group, host:),
      )
    end
  end

  describe "#request_upgrade" do
    let(:organisation) { create :organisation, :with_signed_mou }
    let!(:first_organisation_admin_user) { create :organisation_admin_user, organisation: }
    let!(:second_organisation_admin_user) { create :organisation_admin_user, organisation: }
    let(:editor_user) { create :user, organisation: }
    let(:group) do
      create(:group, organisation:).tap do |group|
        create(:membership, user: editor_user, group:, role: :editor)
        create(:membership, user: current_user, group:, role: :group_admin)
      end
    end
    let(:delivery) { double }

    before do
      allow(GroupUpgradeMailer).to receive(:requested_email).and_return(delivery)
      allow(delivery).to receive(:deliver_now).with(no_args)
    end

    it "sets the upgrade_requester on the group" do
      expect {
        group_service.request_upgrade
      }.to change(group, :upgrade_requester).to(current_user)
    end

    it "sets the group status to upgrade_requested" do
      expect {
        group_service.request_upgrade
      }.to change(group, :status).to("upgrade_requested")
    end

    it "sends an email to all organisation admins" do
      expect(GroupUpgradeMailer).to receive(:requested_email).with(
        to_email: first_organisation_admin_user.email,
        requester_name: current_user.name,
        requester_email_address: current_user.email,
        group_name: group.name,
        view_request_url: group_url(group, host:),
      )

      expect(GroupUpgradeMailer).to receive(:requested_email).with(
        to_email: second_organisation_admin_user.email,
        requester_name: current_user.name,
        requester_email_address: current_user.email,
        group_name: group.name,
        view_request_url: group_url(group, host:),
      )
      group_service.request_upgrade
      expect(delivery).to have_received(:deliver_now).with(no_args).exactly(2).times
    end

    it "does not send an email to a user without the organisation admin role" do
      group_service.request_upgrade
      expect(GroupUpgradeMailer).not_to have_received(:requested_email).with(
        to_email: editor_user.email,
        requester_name: current_user.name,
        requester_email_address: current_user.email,
        group_name: group.name,
        view_request_url: group_url(group, host:),
      )
    end
  end

  describe "#delete_group" do
    let(:org) { create :organisation, :with_signed_mou }
    let(:current_user) { create(:organisation_admin_user, organisation: org) }
    let(:other_user) { create(:organisation_admin_user, organisation: org) }
    let(:group) { create(:group, id: 2, organisation: org) }
    let(:form) { create :form, id: 1 }
    let(:delivery) { double }

    before do
      allow(AdminAlerts::GroupDeleteMailer).to receive_messages(group_deleted_email_org_admin: delivery, group_deleted_email_group_admins_and_editors: delivery)
      allow(delivery).to receive(:deliver_now).with(any_args)
    end

    context "when there are other org admins" do
      let(:org_admins) { create_list(:organisation_admin_user, 2, organisation: org) }

      before do
        org_admins.each do |admin|
          Membership.create!(group: group, user: admin, role: :group_admin, added_by_id: current_user.id)
        end
      end

      it "sends emails to other org admins" do
        group_service.send_group_deleted_emails

        expect(delivery).to have_received(:deliver_now).with(any_args).exactly(2).times

        org_admins.each do |org_admin|
          expect(AdminAlerts::GroupDeleteMailer).to have_received(:group_deleted_email_org_admin).with(
            to_email: org_admin.email,
            org_admin_name: current_user.name,
            org_admin_email_address: current_user.email,
            group_name: group.name,
          )
        end
      end
    end

    context "when there are other group admins" do
      let(:group_admins) { create_list(:user, 2, organisation: org) }

      before do
        group_admins.each do |admin|
          Membership.create!(group: group, user: admin, role: :group_admin, added_by_id: current_user.id)
        end
      end

      it "sends emails to group admins" do
        group_service.send_group_deleted_emails

        expect(delivery).to have_received(:deliver_now).with(any_args).exactly(2).times

        group_admins.each do |user|
          expect(AdminAlerts::GroupDeleteMailer).to have_received(:group_deleted_email_group_admins_and_editors).with(
            to_email: user.email,
            org_admin_name: current_user.name,
            org_admin_email_address: current_user.email,
            group_name: group.name,
          )
        end
      end
    end

    context "when there are group editors" do
      let(:group_editors) { create_list(:user, 2, organisation: org) }

      before do
        group_editors.each do |admin|
          Membership.create!(group: group, user: admin, role: :editor, added_by_id: current_user.id)
        end
      end

      it "sends emails to group editors" do
        group_service.send_group_deleted_emails

        expect(delivery).to have_received(:deliver_now).with(any_args).exactly(2).times

        group_editors.each do |user|
          expect(AdminAlerts::GroupDeleteMailer).to have_received(:group_deleted_email_group_admins_and_editors).with(
            to_email: user.email,
            org_admin_name: current_user.name,
            org_admin_email_address: current_user.email,
            group_name: group.name,
          )
        end
      end
    end
  end
end
