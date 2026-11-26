require "rails_helper"

describe PendingUser do
  subject(:pending_user) do
    described_class.start(
      session,
      provider: "auth0",
      uid: "123456",
      email: "new.user@Example.gov.uk",
      auth0_connection_strategy: "email",
    )
  end

  let(:session) { {} }
  let(:organisation) { create(:organisation) }

  describe ".start" do
    it "stores the user's details in the session" do
      pending_user

      expect(session[described_class::SESSION_KEY]).to eq(
        "provider" => "auth0",
        "uid" => "123456",
        "email" => "new.user@Example.gov.uk",
        "name" => nil,
        "organisation_id" => nil,
        "auth0_connection_strategy" => "email",
      )
    end

    it "can be given a name and organisation" do
      described_class.start(session, provider: "auth0", uid: "123456", email: "user@example.gov.uk", name: "Name", organisation_id: organisation.id)

      expect(described_class.from_session(session)).to have_attributes(name: "Name", organisation_id: organisation.id)
    end
  end

  describe ".from_session" do
    it "returns nil if there is no pending user in the session" do
      expect(described_class.from_session({})).to be_nil
    end

    it "returns a pending user with the details from the session" do
      pending_user

      expect(described_class.from_session(session)).to have_attributes(
        provider: "auth0",
        uid: "123456",
        email: "new.user@Example.gov.uk",
        name: nil,
        organisation_id: nil,
        auth0_connection_strategy: "email",
      )
    end
  end

  describe ".clear" do
    it "removes the pending user from the session" do
      pending_user
      described_class.clear(session)

      expect(described_class.from_session(session)).to be_nil
    end
  end

  describe "#email_domain" do
    it "returns the domain of the email address" do
      expect(pending_user.email_domain).to eq "example.gov.uk"
    end
  end

  describe "#save!" do
    it "stores the name and organisation in the session" do
      pending_user.name = "New User"
      pending_user.organisation_id = organisation.id

      expect { pending_user.save! }.not_to change(User, :count)

      expect(described_class.from_session(session)).to have_attributes(name: "New User", organisation_id: organisation.id)
    end
  end

  describe "#next_account_path" do
    it "returns the organisation path if the organisation is not set" do
      expect(pending_user.next_account_path).to eq "/account/organisation/edit"
    end

    it "returns the name path if the organisation is set" do
      pending_user.organisation_id = organisation.id
      expect(pending_user.next_account_path).to eq "/account/name/edit"
    end
  end

  describe "#complete?" do
    it "returns false if the name and organisation are not set" do
      expect(pending_user).not_to be_complete
    end

    it "returns false if only the name is set" do
      pending_user.name = "New User"
      expect(pending_user).not_to be_complete
    end

    it "returns false if only the organisation is set" do
      pending_user.organisation_id = organisation.id
      expect(pending_user).not_to be_complete
    end

    it "returns true if the name and organisation are set" do
      pending_user.name = "New User"
      pending_user.organisation_id = organisation.id
      expect(pending_user).to be_complete
    end
  end

  describe "#complete!" do
    before do
      pending_user.name = "New User"
      pending_user.organisation_id = organisation.id
    end

    context "when the user does not exist" do
      it "creates the user" do
        expect { pending_user.complete! }.to change(User, :count).by(1)

        expect(User.last).to have_attributes(
          provider: "auth0",
          uid: "123456",
          email: "new.user@Example.gov.uk",
          name: "New User",
          organisation:,
        )
      end

      it "returns the created user" do
        expect(pending_user.complete!).to eq User.last
      end
    end

    context "when the user already exists" do
      let!(:user) { create(:user, :with_no_org, provider: "auth0", uid: "123456", email: "new.user@example.gov.uk", name: nil) }

      it "updates the user's name and organisation" do
        expect { pending_user.complete! }.not_to change(User, :count)

        expect(user.reload).to have_attributes(name: "New User", organisation:)
      end

      it "returns the user" do
        expect(pending_user.complete!).to eq user
      end
    end

    context "when the email domain restricts access" do
      subject(:pending_user) do
        described_class.start(session, provider: "auth0", uid: "123456", email: "new.user@dwp.gov.uk")
      end

      it "creates the user without access" do
        expect(pending_user.complete!.has_access).to be false
      end
    end

    it "clears the pending user from the session" do
      pending_user.complete!
      expect(described_class.from_session(session)).to be_nil
    end
  end
end
