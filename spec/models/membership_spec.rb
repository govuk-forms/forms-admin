require "rails_helper"

RSpec.describe Membership, type: :model do
  it "has a valid factory" do
    expect(build(:membership)).to be_valid
  end

  it "is invalid without a user" do
    membership = build :membership, user: nil
    expect(membership).not_to be_valid
  end

  it "is invalid without a group" do
    membership = build :membership, group: nil
    expect(membership).not_to be_valid
  end

  it "is invalid without an added_by" do
    membership = build :membership, added_by: nil
    expect(membership).not_to be_valid
  end

  it "is invalid without a role" do
    membership = build :membership, role: nil
    expect(membership).not_to be_valid
  end

  it "is invalid if the user and group are not in the same organisation" do
    org1 = create :organisation, id: 1, slug: "test-org"
    org2 = create :organisation, id: 2, slug: "ministry-of-testing"
    user = create :user, organisation: org1
    group = create :group, organisation: org2
    membership = build(:membership, user:, group:)
    expect(membership).not_to be_valid
  end

  it "is invalid if the user is already a member of the group" do
    organisation = create :organisation
    user = create :user, organisation: organisation
    group = create :group, organisation: organisation
    create(:membership, user:, group:)
    membership = build(:membership, user:, group:)
    expect(membership).not_to be_valid
  end

  it "raises a DB error if the user is already a member of the group" do
    organisation = create :organisation
    user = create :user, organisation: organisation
    group = create :group, organisation: organisation
    create(:membership, user:, group:)
    membership = build(:membership, user:, group:)
    expect { membership.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  describe ".destroy_invalid_organisation_memberships" do
    it "does not remove memberships for the same organisation" do
      org1 = create :organisation, id: 1, slug: "test-org"
      user = create :user, organisation: org1
      group = create :group, organisation: org1
      membership = create(:membership, user:, group:)

      described_class.destroy_invalid_organisation_memberships(user)
      expect(described_class.exists?(membership.id)).to be true
    end

    it "removes mismatched memberships" do
      org1 = create :organisation, id: 1, slug: "test-org"
      org2 = create :organisation, id: 2, slug: "ministry-of-testing"
      user = create :user, organisation: org1
      group = create :group, organisation: org1
      membership = create(:membership, user:, group:)

      user.organisation = org2
      described_class.destroy_invalid_organisation_memberships(user)
      expect(described_class.exists?(membership.id)).to be false
    end

    it "does not remove memberships for other users" do
      org1 = create :organisation, id: 1, slug: "test-org"
      org2 = create :organisation, id: 2, slug: "ministry-of-testing"

      user1 = create :user, organisation: org1
      user2 = create :user, organisation: org1

      group = create :group, organisation: org1
      create(:membership, user: user1, group:)
      membership2 = create(:membership, user: user2, group:)

      user2.organisation = org2

      described_class.destroy_invalid_organisation_memberships(user1)
      expect(described_class.exists?(membership2.id)).to be true
    end
  end

  describe "role" do
    it "has a default role of editor" do
      membership = build :membership
      expect(membership.role).to eq("editor")
    end

    it "can be set to group_admin" do
      membership = build :membership, role: :group_admin
      expect(membership).to be_valid
    end
  end
end
