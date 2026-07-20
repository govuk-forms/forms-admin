require "rails_helper"

describe User, type: :model do
  subject(:user) { described_class.new }

  let(:organisation) { create :organisation }

  describe "validations" do
    it "validates" do
      expect(user).to be_valid
    end

    describe "role" do
      it "is invalid if blank" do
        user.role = nil

        expect(user).to be_invalid
      end
    end

    describe "organisation_id" do
      it "is allowed to be nil" do
        user.organisation_id = nil

        expect(user).to be_valid
      end
    end

    describe "email" do
      it "does not allow users to be created with the same email with different case" do
        create(:user, email: "foo.bar@email.gov.uk")

        expect {
          described_class.create!(name: Faker.name, email: "Foo.Bar@email.gov.uk", role: :standard, organisation_id: organisation.id)
        }.to raise_error ActiveRecord::RecordInvalid, /Email has already been taken/
      end
    end

    context "when updating organisation" do
      let(:user) { create :user, :with_no_org }

      it "is valid to leave organisation unset" do
        user.organisation_id = nil
        expect(user).to be_valid
      end

      it "is not valid to unset organisation if it is already set" do
        user.organisation = create(:organisation, slug: "test-org")
        user.save!

        user.organisation_id = nil
        expect(user).to be_invalid
      end

      it "is not valid to leave organisation unset if changing role to organisation admin" do
        user.role = :organisation_admin
        expect(user).to be_invalid
      end
    end

    context "when reassigning to a new, unsaved organisation" do
      let(:user) { create(:user, organisation: create(:organisation)) }

      it "is valid even though the new organisation is not yet persisted" do
        user.organisation = build(:organisation)

        expect(user).to be_valid
      end
    end

    context "when updating name" do
      let(:user) { create :user, :with_no_name }

      it "is valid to leave name unset" do
        user.name = nil
        expect(user).to be_valid
      end

      context "when user somehow has no name" do
        let(:user) do
          user = build(:user, :with_no_name)
          user.save!(validate: false)
          user
        end

        it "is valid to leave name unset" do
          user.name = nil
          expect(user).to be_valid
        end
      end

      it "is not valid to unset name if it is already set" do
        user.update!(name: "Test User")
        user.name = nil
        expect(user).to be_invalid
      end
    end

    context "when the user belongs to an organisation that doesn't have a signed mou" do
      let(:organisation) { create(:organisation) }
      let(:user) { create(:user, organisation:) }

      it "is not valid for a user's role to be organisation_admin" do
        user.role = :organisation_admin
        expect(user).to be_invalid
      end

      it "is valid for a user's role to be standard" do
        user.role = :standard
        expect(user).to be_valid
      end
    end

    context "when the user belongs to an organisation that does have a signed mou" do
      let(:organisation) { create(:organisation, :with_signed_mou) }
      let(:user) { create(:user, organisation:) }

      it "is valid for a user's role to be organisation_admin" do
        user.role = :organisation_admin
        expect(user).to be_valid
      end
    end
  end

  describe "versioning", :versioning do
    it "enables paper trail" do
      expect(user).to be_versioned
    end
  end

  describe "role enum" do
    it "returns a list of roles" do
      expect(described_class.roles.keys).to eq(%w[super_admin organisation_admin standard])
      expect(described_class.roles.values).to eq(%w[super_admin organisation_admin standard])
    end
  end

  describe "associations" do
    it "destroys associated memberships" do
      user = create(:user)
      group = create(:group, organisation: user.organisation)

      membership = create(:membership, user:, group:)
      user.destroy!

      expect { membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "scopes" do
    describe ".for_users_list" do
      let(:organisation) { create :organisation, slug: "ministry-of-tests", name: "Ministry of Tests" }
      let(:other_org) { create(:organisation, slug: "agriculture-department", name: "Agriculture Department") }

      let!(:second_user_alphabetically) { create(:user, name: "Betty Test", organisation:, role: "standard") }
      let!(:first_user_alphabetically) { create(:user, name: "Aaron Test", organisation:, role: "standard") }
      let!(:org_admin_user) { create(:user, name: "Wesley Test", organisation:) }
      let!(:super_admin_user) { create(:user, name: "Yvette Test", organisation:, role: "super_admin") }
      let!(:without_access_user) { create(:user, name: "Amy Test", organisation:, has_access: false, role: "standard") }
      let!(:user_with_first_org_alphabetically) { create(:user, name: "Tim Test", organisation: other_org, role: "standard") }
      let!(:user_with_no_org) { create(:user, organisation: nil, name: "Annie Test") }

      before do
        create(:mou_signature, organisation:, user: first_user_alphabetically)
        organisation.reload
        org_admin_user.organisation_admin!
      end

      it "returns users ordered by org name, access, role then name" do
        expect(described_class.for_users_list).to eq [
          user_with_no_org,
          user_with_first_org_alphabetically,
          super_admin_user,
          org_admin_user,
          first_user_alphabetically,
          second_user_alphabetically,
          without_access_user,
        ]
      end
    end

    describe "filter scopes" do
      before do
        other_org = create :organisation, slug: "other-org"
        create_list(:user, 2, organisation: other_org)
      end

      describe ".by_name" do
        let!(:matched_user) { create(:user, name: "Sir Abcdefg Higjklmop") }
        let!(:other_matched_user) { create(:user, name: "Lord Abcdefg Smith") }

        it "returns users with partial match" do
          expect(described_class.by_name("Abcdefg")).to contain_exactly(matched_user, other_matched_user)
        end

        it "returns users with case insensitive match" do
          expect(described_class.by_name("Higjklmop")).to contain_exactly(matched_user)
        end

        it "returns all users when provided name is nil" do
          expect(described_class.by_name(nil).size).to eq 4
        end

        it "returns all users when provided name is blank" do
          expect(described_class.by_name("").size).to eq 4
        end
      end

      describe ".by_email" do
        let!(:matched_user) { create(:user, email: "sir.abcdefg.higjklmnop@example.com") }
        let!(:other_matched_user) { create(:user, email: "lord.abcdefg.smith@example.com") }

        it "returns users with partial match" do
          expect(described_class.by_email(".abcdefg")).to contain_exactly(matched_user, other_matched_user)
        end

        it "returns the user with an exact match" do
          expect(described_class.by_email("sir.abcdefg.higjklmnop@example.com")).to contain_exactly(matched_user)
        end

        it "returns users with case insensitive match" do
          expect(described_class.by_email("HIGJKLMNOP")).to contain_exactly(matched_user)
        end

        it "returns all users when provided email is nil" do
          expect(described_class.by_email(nil).size).to eq 4
        end

        it "returns all users when provided email is blank" do
          expect(described_class.by_email("").size).to eq 4
        end
      end

      describe ".by_organisation_id" do
        let!(:matched_user) { create(:user, organisation: organisation) }

        it "returns users with given organisation_id" do
          expect(described_class.by_organisation_id(organisation.id)).to contain_exactly(matched_user)
        end

        it "returns all users when organisation_id is nil" do
          expect(described_class.by_organisation_id(nil).size).to eq 3
        end

        it "returns all users when organisation_id is blank" do
          expect(described_class.by_organisation_id("").size).to eq 3
        end
      end

      describe ".by_role" do
        let!(:matched_user) { create(:user, role: :super_admin) }

        it "returns users with given role" do
          expect(described_class.by_role("super_admin")).to contain_exactly(matched_user)
        end

        it "returns all users when role is nil" do
          expect(described_class.by_role(nil).size).to eq 3
        end

        it "returns all users when role is blank" do
          expect(described_class.by_role("").size).to eq 3
        end
      end

      describe ".by_has_access" do
        let!(:user_without_access) { create(:user, has_access: false) }

        it "returns users without access" do
          expect(described_class.by_has_access("false")).to contain_exactly(user_without_access)
        end

        it "returns users with access" do
          expect(described_class.by_has_access("true").size).to eq 2
        end

        it "returns all users when has_access is nil" do
          expect(described_class.by_has_access(nil).size).to eq 3
        end

        it "returns all users when has_access is blank" do
          expect(described_class.by_has_access("").size).to eq 3
        end
      end
    end
  end

  describe ".find_for_auth" do
    let!(:user) do
      create :user, provider: "test", uid: "123456", name: "Test User", email: "test.User@example.com"
    end

    it "finds a user by uid" do
      expect(described_class.find_for_auth(provider: "test", uid: "123456"))
        .to eq user
    end

    it "avoids uid collisions" do
      expect(described_class.find_for_auth(provider: "other", uid: "123456", email: "someone@example.com"))
        .not_to eq user
    end

    it "finds a user by email address, ignoring the case, when no user is found with uid" do
      expect(described_class.find_for_auth(uid: "111111", email: "Test.user@example.com"))
        .to eq user

      expect(user.reload.uid).to eq "111111"
    end

    it "creates a user if one does not already exist" do
      allow(described_class).to receive(:create!)

      described_class.find_for_auth(
        provider: "test",
        uid: "9999",
        email: "fake@example.com",
        name: "Fake Name",
      )

      expect(described_class).to have_received(:create!)
    end

    it "updates any user attributes that have changed" do
      described_class.find_for_auth(
        provider: "test",
        uid: "123456",
        name: "New Name",
      )

      expect(user.reload.name).to eq "New Name"
    end

    it "logs attributes that will be updated" do
      allow(Rails.logger).to receive(:info)

      described_class.find_for_auth(
        provider: "test",
        uid: "111111",
        name: "Test A. User",
        email: "test.User@example.com",
      )

      expect(Rails.logger).to have_received(:info).with("User attributes updated upon authorisation", {
        "user_changes": {
          uid: %w[123456 111111],
          name: ["Test User", "Test A. User"],
        },
      })
    end
  end

  it "defaults to the standard role" do
    user = described_class.new
    expect(user.role).to eq("standard")
  end

  describe "#given_organisation?" do
    it "returns true when organisation_id is set" do
      user = create(:user, :with_no_org)
      user.update!(organisation: build(:organisation))
      expect(user).to be_given_organisation
    end

    it "returns false when organisation_id is not set" do
      user = create(:user, :with_no_org)
      expect(user).not_to be_given_organisation
    end

    it "returns false when organisation_id is set to nil" do
      user = create(:user, :with_no_org)
      user.update!(organisation: nil)
      expect(user).not_to be_given_organisation
    end

    it "returns false when user had an organisation" do
      user = create(:user)
      user.update!(organisation: create(:organisation))
      expect(user).not_to be_given_organisation
    end
  end

  describe "#can_administer_org?" do
    context "when the user is a super admin" do
      it "returns true" do
        user = create(:super_admin_user)

        expect(user.can_administer_org?(organisation)).to be(true)
      end
    end

    context "when the user is an organisation admin" do
      it "returns true" do
        user = create(:organisation_admin_user, organisation: create(:organisation, :with_signed_mou))

        expect(user.can_administer_org?(user.organisation)).to be(true)
      end
    end

    context "when the user is a standard user" do
      it "returns false" do
        user = create(:user)

        expect(user.can_administer_org?(organisation)).to be(false)
      end
    end
  end

  describe "#is_organisations_admin?" do
    context "when the user does not have the organisation admin role" do
      it "returns false" do
        user = create(:user)
        expect(user.is_organisations_admin?(user.organisation)).to be(false)
      end
    end

    context "when the user has the organisation admin role" do
      context "and the user's organisation is the same as given" do
        it "returns true" do
          user = create(:organisation_admin_user)
          expect(user.is_organisations_admin?(user.organisation)).to be(true)
        end
      end

      context "and the user's organisation is not the same as given" do
        it "returns false" do
          user = create(:organisation_admin_user)
          other_org = build(:organisation)

          expect(user.is_organisations_admin?(other_org)).to be(false)
        end
      end
    end
  end

  describe "versioning" do
    with_versioning do
      it "creates a version when role is changed" do
        user = create :user
        expect {
          user.update!(role: :super_admin)
        }.to change { user.versions.size }.by(1)
      end

      it "creates a version when organisation_id is changed" do
        user = create :user, :with_no_org
        expect {
          org = create :organisation
          user.update!(organisation: org)
        }.to change { user.versions.size }.by(1)
      end

      it "creates a version when has_access is changed" do
        user = create :user
        expect {
          user.update!(has_access: false)
        }.to change { user.versions.size }.by(1)
      end

      it "does not create a version when other attributes are changed" do
        user = create :user
        expect {
          user.update(name: "new_name", email: "new_email@example.gov.uk", uid: Faker::Internet.uuid, provider: "new_provider")
        }.not_to(change { user.versions.size })
      end
    end
  end

  describe "creation callbacks" do
    it "allow access for users with an unrestricted email domain" do
      user = create(:user)

      expect(user.organisation_restricted_access?).to be(false)
      expect(user.has_access).to be(true)
    end

    it "allow access for users without an email address" do
      user = create(:user, email: nil)

      expect(user.organisation_restricted_access?).to be(false)
      expect(user.has_access).to be(true)
    end

    User::EMAIL_DOMAIN_DENYLIST.each do |email_domain|
      it "deny access for users with a restricted email domain" do
        user = create(:user, email: "test@#{email_domain}")

        expect(user.organisation_restricted_access?).to be(true)
        expect(user.has_access).to be(false)
      end
    end
  end

  describe "is_group_admin?" do
    let(:user) { create(:user, organisation:) }
    let(:organisation) { create(:organisation, slug: "org") }
    let(:group) { create(:group, organisation:) }

    it "returns falsey when user is not in group" do
      expect(user).not_to be_is_group_admin(group)
    end

    it "returns falsey when a user is an editor of the group" do
      create(:membership, user:, group:, role: :editor)
      expect(user).not_to be_is_group_admin(group)
    end

    it "returns true when user is a group admin of the group" do
      create(:membership, user:, group:, role: :group_admin)
      expect(user.is_group_admin?(group)).to be(true)
    end
  end

  describe "#current_org_has_mou?" do
    let(:user) { create(:user, organisation:) }

    context "when current org has a signed mou" do
      let(:organisation) { create(:organisation, :with_signed_mou) }

      it "returns true" do
        expect(user.current_org_has_mou?).to be(true)
      end
    end

    context "when current org does not have a signed mou" do
      let(:organisation) { create(:organisation) }

      it "returns false" do
        expect(user.current_org_has_mou?).to be(false)
      end
    end

    context "when the user does not have an organisation" do
      let(:organisation) { nil }

      it "returns false" do
        expect(user.current_org_has_mou?).to be(false)
      end
    end
  end

  describe "#collect_analytics?" do
    before do
      allow(Settings).to receive(:analytics_enabled).and_return(analytics_enabled)
    end

    context "when the analytics settings flag is off" do
      let(:analytics_enabled) { false }

      context "when the user is a super admin" do
        let(:user) { create :super_admin_user }

        it "returns false" do
          expect(user.collect_analytics?).to be(false)
        end
      end

      context "when the user is not a super admin" do
        let(:user) { create :user }

        it "returns false" do
          expect(user.collect_analytics?).to be(false)
        end
      end
    end

    context "when the analytics settings flag is on" do
      let(:analytics_enabled) { true }

      context "when the user is a super admin" do
        let(:user) { create :super_admin_user }

        it "returns false" do
          expect(user.collect_analytics?).to be(false)
        end
      end

      context "when the user is not a super admin" do
        let(:user) { create :user }

        it "returns true" do
          expect(user.collect_analytics?).to be(true)
        end
      end
    end
  end

  describe "#signed_in!" do
    around do |example|
      freeze_time do
        example.run
      end
    end

    it "updates last_signed_in_at" do
      expect {
        user.signed_in!
      }.to change(user, :last_signed_in_at).to(Time.zone.now)
    end
  end
end
