require "rails_helper"

RSpec.describe GroupPolicy do
  subject(:policy) { described_class.new(user, group) }

  let(:user) { create :user, organisation: group.organisation }
  let(:group) { build :group, :org_has_org_admin }

  context "when user is super_admin" do
    let(:user) { build :super_admin_user }

    it { is_expected.to permit_actions(%i[delete destroy]) }

    it "forbids only request_upgrade and review_upgrade" do
      expect(policy).to forbid_only_actions(%i[request_upgrade review_upgrade])
    end

    it "scope resolves to all groups" do
      expect(GroupPolicy::Scope.new(user, Group).resolve).to eq(Group.all)
    end

    it "permits manage_feature_flags" do
      expect(policy).to permit_action(:manage_feature_flags)
    end

    context "when the group has status upgrade_requested" do
      let(:group) { build :group, status: :upgrade_requested }

      it "permits review_upgrade" do
        expect(policy).to permit_action(:review_upgrade)
      end
    end

    context "when the group organisation does not have an MOU" do
      let(:group) { build(:group) }

      it "forbids upgrade" do
        expect(policy).to forbid_action(:upgrade)
      end
    end
  end

  context "when user is organisation_admin" do
    let(:user) { build :organisation_admin_user, organisation: }
    let(:organisation) { group.organisation }

    context "and in the same organisation as the group" do
      it "forbids only request_upgrade, review_upgrade, move and manage_feature_flags" do
        expect(policy).to forbid_only_actions(%i[request_upgrade review_upgrade move manage_feature_flags])
      end
    end

    context "and not in the same organisation as the group" do
      let(:organisation) { create :organisation, slug: "another organisation" }

      it "permits new and create only" do
        expect(policy).to permit_only_actions(%i[new create])
      end
    end

    context "when the group has status upgrade_requested" do
      let(:group) { build :group, status: :upgrade_requested }

      it "permits review_upgrade" do
        expect(policy).to permit_action(:review_upgrade)
      end
    end

    it "scope resolves to groups user organisation admin for" do
      expect(GroupPolicy::Scope.new(user, Group).resolve).to eq(Group.for_organisation(user.organisation))
    end
  end

  context "when user is editor" do
    it "permits new and create only" do
      expect(policy).to permit_only_actions(%i[new create])
    end

    context "and user belongs to group as an editor" do
      before do
        create :membership, user:, group:, role: :editor
      end

      it "permits group creation, viewing, and editing" do
        expect(policy).to permit_only_actions(%i[show new create])
      end
    end

    it "scope resolves to only group user is a member of" do
      expect(GroupPolicy::Scope.new(user, Group).resolve).to eq(Group.for_user(user))
    end

    context "and user belongs to group as a group admin" do
      before do
        create :membership, user:, group:, role: :group_admin
      end

      it "forbids upgrade, add_group_admin, review_upgrade, delete and destroy" do
        expect(policy).to forbid_only_actions(%i[upgrade add_group_admin review_upgrade delete destroy move manage_feature_flags])
      end

      context "when the group status is active" do
        before do
          group.active!
        end

        it "forbids request_upgrade" do
          expect(policy).to forbid_action(:request_upgrade)
        end
      end

      context "when the group status is upgrade_requested" do
        before do
          group.upgrade_requested!
        end

        it "permits request_upgrade" do
          expect(policy).to permit_action(:request_upgrade)
        end
      end

      context "when the group status is trial" do
        before do
          group.trial!
        end

        it "permits request_upgrade" do
          expect(policy).to permit_action(:request_upgrade)
        end
      end

      context "when the group belongs to an organisation without an org admin" do
        let(:group) { build :group }

        it "forbids request_upgrade" do
          expect(policy).to forbid_action(:request_upgrade)
        end
      end
    end
  end
end
