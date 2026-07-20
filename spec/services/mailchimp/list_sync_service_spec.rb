require "rails_helper"

RSpec.describe Mailchimp::ListSyncService do
  subject(:mailchimp_list_sync_service) do
    described_class.new
  end

  describe "#synchronize_lists" do
    let(:users_with_access) do
      10.times.map { Faker::Internet.unique.email }
    end

    let(:users_without_access) do
      10.times.map { Faker::Internet.unique.email }
    end

    let(:mou_signer_with_access) { users_with_access.first }

    let(:mou_signer_without_access) { users_without_access.first }

    let(:organisation_admin_with_access) { users_with_access.second }
    let(:mou_signer_and_organisation_admin_with_access) { users_with_access.third }

    before do
      signed_mou_org = create(:organisation)
      signed_mou_org_user = create(:user, organisation: signed_mou_org, has_access: false)
      create(:mou_signature, organisation: signed_mou_org, user: signed_mou_org_user)
      users_with_access.each do |email|
        create :user, email:, has_access: true, organisation: signed_mou_org
      end

      users_without_access.each do |email|
        create :user, email:, has_access: false
      end

      # Create MOU signature with an active user
      create :mou_signature, user: User.where(email: mou_signer_with_access).first

      # Create MOU signature with an inactive user
      create :mou_signature, user: User.where(email: mou_signer_without_access).first

      # Create MOU signature for org admin user
      create :mou_signature, user: User.where(email: mou_signer_and_organisation_admin_with_access).first

      # set organisation admins
      User.find_by(email: organisation_admin_with_access).organisation_admin!
      User.find_by(email: mou_signer_and_organisation_admin_with_access).organisation_admin!
    end

    it "runs the mailchimp synchronization on each list" do
      active_users_list_synchronizer = instance_double(Mailchimp::ListSynchronizer)
      mou_signers_list_synchronizer = instance_double(Mailchimp::ListSynchronizer)
      allow(Mailchimp::ListSynchronizer).to receive(:new).with(list_id: Settings.mailchimp.active_users_list).and_return(active_users_list_synchronizer)
      allow(Mailchimp::ListSynchronizer).to receive(:new).with(list_id: Settings.mailchimp.mou_signers_list).and_return(mou_signers_list_synchronizer)

      expect(active_users_list_synchronizer).to receive(:synchronize).with(desired_members: match_array(
        users_with_access
          .map { |email| Mailchimp::Member.new(email: email, status: "subscribed") },
      )).once

      expect(mou_signers_list_synchronizer).to receive(:synchronize).with(desired_members: contain_exactly(
        Mailchimp::Member.new(email: mou_signer_with_access, status: "subscribed", role: "Agreed MOU"),
        Mailchimp::Member.new(email: organisation_admin_with_access, status: "subscribed", role: "Organisation admin"),
        Mailchimp::Member.new(email: mou_signer_and_organisation_admin_with_access, status: "subscribed", role: "Organisation admin agreed MOU"),
      )).once

      expect(Rails.logger).to receive(:debug).with("Synchronizing active users mailing list").once
      expect(Rails.logger).to receive(:debug).with("Synchronizing MOU signers mailing list").once

      mailchimp_list_sync_service.synchronize_lists
    end
  end

  describe "#mou_signers" do
    let(:signed_mou_org) { create(:organisation) }
    let(:user_with_access_and_mou) { create(:user, email: "mou_user@example.com", organisation: signed_mou_org) }
    let(:user_with_access_admin) { create(:user, email: "admin_user@example.com", organisation: signed_mou_org) }
    let(:user_without_access) { create(:user, email: "inactive_user@example.com", has_access: false, organisation: signed_mou_org) }
    let(:user_access_and_admin_with_mou) { create(:user, email: "admin_mou_user@example.com", organisation: signed_mou_org) }
    let(:non_crown_org) { create(:organisation, slug: "non-crown-org") }
    let(:user_that_signed_non_crown_agreement) { create(:user, organisation: non_crown_org) }
    let(:not_org_admin_that_signed_non_crown_agreement) { create(:user, organisation: non_crown_org) }
    let(:org_admin_for_non_crown_org) { create(:user, organisation: non_crown_org) }
    let!(:signed_mou_org_user) { create(:user, organisation: signed_mou_org, has_access: false) }

    before do
      create(:mou_signature, organisation: signed_mou_org, user: signed_mou_org_user)
      create(:mou_signature, user: user_with_access_and_mou)
      create(:mou_signature, user: user_access_and_admin_with_mou)
      create(:mou_signature, agreement_type: :non_crown, user: user_that_signed_non_crown_agreement)
      create(:mou_signature, agreement_type: :non_crown, user: not_org_admin_that_signed_non_crown_agreement)
      user_with_access_admin.reload.organisation_admin!
      user_access_and_admin_with_mou.reload.organisation_admin!
      user_that_signed_non_crown_agreement.reload.organisation_admin!
      org_admin_for_non_crown_org.reload.organisation_admin!
    end

    it "returns MOU signers with access and correct roles" do
      expected_members = [
        Mailchimp::Member.new(email: "mou_user@example.com", status: "subscribed", role: "Agreed MOU"),
        Mailchimp::Member.new(email: "admin_user@example.com", status: "subscribed", role: "Organisation admin"),
        Mailchimp::Member.new(email: "admin_mou_user@example.com", status: "subscribed", role: "Organisation admin agreed MOU"),
      ]

      expect(mailchimp_list_sync_service.mou_signers).to match_array(expected_members)
    end

    it "does not include users without access" do
      expect(mailchimp_list_sync_service.mou_signers).not_to include(
        Mailchimp::Member.new(email: "inactive_user@example.com", status: "subscribed"),
      )
    end

    it "does not include users that only signed a non-crown agreement" do
      expect(mailchimp_list_sync_service.mou_signers).not_to include(
        Mailchimp::Member.new(email: user_that_signed_non_crown_agreement.email, status: "subscribed"),
        Mailchimp::Member.new(email: not_org_admin_that_signed_non_crown_agreement.email, status: "subscribed"),
        Mailchimp::Member.new(email: org_admin_for_non_crown_org.email, status: "subscribed"),
      )
    end
  end
end
