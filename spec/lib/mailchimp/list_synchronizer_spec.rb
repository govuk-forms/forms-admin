require "rails_helper"

RSpec.describe Mailchimp::ListSynchronizer do
  subject(:mailchimp_list_synchronizer) { described_class }

  before do
    allow($stdout).to receive(:puts)
  end

  describe "#synchronize" do
    let(:mailchimp_client) do
      instance_double(MailchimpMarketing::Client)
    end

    let(:mailchimp_client_lists) do
      instance_double(MailchimpMarketing::ListsApi)
    end

    let(:list_1) do
      {
        "name" => "List 1",
        "stats" => {
          "member_count" => 1,
          "total_contacts" => 1,
        },
      }
    end

    before do
      allow(MailchimpMarketing::Client).to receive(:new).and_return(mailchimp_client)

      allow(mailchimp_client).to receive(:set_config)
      allow(mailchimp_client).to receive(:lists).and_return(mailchimp_client_lists)

      allow(mailchimp_client_lists).to receive(:set_list_member)
      allow(mailchimp_client_lists).to receive(:delete_list_member)

      allow(mailchimp_client_lists).to receive(:get_list) do |list_id|
        case list_id
        when "list-1"
          list_1
        else
          raise "Unknown list id"
        end
      end

      allow(mailchimp_client_lists).to receive(:get_list_members_info) do |list_id|
        case list_id
        when "list-1"
          list_1_members_info
        else
          raise "Unknown list id"
        end
      end

      ENV["SETTINGS__MAILCHIMP__API_KEY"] = "KEY"
    end

    RSpec.shared_examples "it subscribes the user" do
      it "subscribes the user" do
        expect(mailchimp_client_lists).to receive(:set_list_member).with(
          "list-1",
          anything,
          {
            "email_address" => "user@domain.org",
            "status" => "subscribed",
          },
        )

        described_class.new(list_id: "list-1").synchronize(desired_members:)
      end
    end

    RSpec.shared_examples "it archives the user" do
      it "archives the user" do
        archived_email_hash = Digest::MD5.hexdigest "user@domain.org"

        expect(mailchimp_client_lists).to receive(:delete_list_member).with("list-1", archived_email_hash)

        described_class.new(list_id: "list-1").synchronize(desired_members:)
      end
    end

    RSpec.shared_examples "it does not subscribe or archive the user" do
      it "does not subscribe or archive the user" do
        expect(mailchimp_client_lists).not_to receive(:set_list_member)
        expect(mailchimp_client_lists).not_to receive(:delete_list_member)

        described_class.new(list_id: "list-1").synchronize(desired_members:)
      end
    end

    RSpec.shared_examples "it does not subscribe or archive the user in question" do
      it "subscribes other users in the list, but not the current user" do
        # the API should only receive one subscribe request, for a different email address
        expect(mailchimp_client_lists).to receive(:set_list_member).once do |_list_id, _subscriber_hash, body|
          expect(body["email_address"]).to eq("some_other_user@domain.org")
        end

        described_class.new(list_id: "list-1").synchronize(desired_members:)
      end

      it "does not archive the user" do
        expect(mailchimp_client_lists).not_to receive(:delete_list_member)

        described_class.new(list_id: "list-1").synchronize(desired_members:)
      end
    end

    context "when the user is in the list of users to synchronize" do
      let(:desired_members) { [Mailchimp::Member.new(email: "user@domain.org", status: "subscribed")] }

      context "when the user is not present in the MailChimp list" do
        let(:list_1_members_info) do
          {
            "members" => [],
          }
        end

        include_examples "it subscribes the user"
      end

      context "when the user is subscribed in MailChimp" do
        let(:list_1_members_info) do
          {
            "members" => [
              { "email_address" => "user@domain.org", "status" => "subscribed" },
            ],
          }
        end

        include_examples "it does not subscribe or archive the user"
      end

      context "when the user is unsubscribed in MailChimp" do
        let(:list_1_members_info) do
          {
            "members" => [
              { "email_address" => "user@domain.org", "status" => "unsubscribed" },
            ],
          }
        end

        include_examples "it does not subscribe or archive the user"
      end

      context "when the user is archived in MailChimp" do
        let(:list_1_members_info) do
          {
            "members" => [
              { "email_address" => "user@domain.org", "status" => "archived" },
            ],
          }
        end

        include_examples "it subscribes the user"
      end

      context "when the user is 'cleaned' in MailChimp" do
        let(:list_1_members_info) do
          {
            "members" => [
              { "email_address" => "user@domain.org", "status" => "cleaned" },
            ],
          }
        end

        include_examples "it subscribes the user"
      end

      context "when the user is 'pending' in MailChimp" do
        let(:list_1_members_info) do
          {
            "members" => [
              { "email_address" => "user@domain.org", "status" => "pending" },
            ],
          }
        end

        include_examples "it subscribes the user"
      end

      context "when the user is 'transactional' in MailChimp" do
        let(:list_1_members_info) do
          {
            "members" => [
              { "email_address" => "user@domain.org", "status" => "transactional" },
            ],
          }
        end

        include_examples "it subscribes the user"
      end
    end

    context "when the user is not in the list of users to synchronize" do
      let(:desired_members) { [Mailchimp::Member.new(email: "some_other_user@domain.org", status: "subscribed")] }

      context "when the user is not present in the MailChimp list" do
        let(:list_1_members_info) do
          {
            "members" => [],
          }
        end

        include_examples "it does not subscribe or archive the user in question"
      end

      context "when the user is subscribed in MailChimp" do
        let(:list_1_members_info) do
          {
            "members" => [
              { "email_address" => "user@domain.org", "status" => "subscribed" },
            ],
          }
        end

        include_examples "it archives the user"
      end

      context "when the user is unsubscribed in MailChimp" do
        let(:list_1_members_info) do
          {
            "members" => [
              { "email_address" => "user@domain.org", "status" => "unsubscribed" },
            ],
          }
        end

        include_examples "it does not subscribe or archive the user in question"
      end

      context "when the user is archived in MailChimp" do
        let(:list_1_members_info) do
          {
            "members" => [
              { "email_address" => "user@domain.org", "status" => "archived" },
            ],
          }
        end

        include_examples "it does not subscribe or archive the user in question"
      end

      context "when the user is 'cleaned' in MailChimp" do
        let(:list_1_members_info) do
          {
            "members" => [
              { "email_address" => "user@domain.org", "status" => "cleaned" },
            ],
          }
        end

        include_examples "it archives the user"
      end

      context "when the user is 'pending' in MailChimp" do
        let(:list_1_members_info) do
          {
            "members" => [
              { "email_address" => "user@domain.org", "status" => "pending" },
            ],
          }
        end

        include_examples "it archives the user"
      end

      context "when the user is 'transactional' in MailChimp" do
        let(:list_1_members_info) do
          {
            "members" => [
              { "email_address" => "user@domain.org", "status" => "transactional" },
            ],
          }
        end

        include_examples "it archives the user"
      end
    end

    context "when the mailing list has more than 1000 members" do
      let(:desired_members) { [Mailchimp::Member.new(email: "some_email_address@domain.org", status: "subscribed")] }

      let(:list_1) do
        {
          "name" => "List 1",
          "stats" => {
            "member_count" => 995,
            "total_contacts" => 1001,
          },
        }
      end

      let(:list_1_members_info) do
        {
          "members" =>
          1001.times.map { { "email_address" => Faker::Internet.unique.email, "status" => "subscribed" } },
        }
      end

      it "handles all of the results" do
        expect(mailchimp_client_lists).to receive(:delete_list_member).with("list-1", anything).exactly(1001).times

        described_class.new(list_id: "list-1").synchronize(desired_members:)
      end
    end

    context "when there is a MailChimp API error" do
      let(:desired_members) { [Mailchimp::Member.new(email: "user@domain.org", status: "subscribed")] }

      let(:list_1_members_info) do
        {
          "members" => [],
        }
      end

      before do
        allow(Rails.logger).to receive(:warn)
      end

      it "logs the issue when the response_body is available" do
        response_body = <<~HEREDOC
          {
            "title": "Member In Compliance State",
            "status": 400,
            "detail": "user@domain.org is in a compliance state due to unsubscribe, bounce, or compliance review and cannot be subscribed.",
            "instance": "ecc64220-55ff-d413-6c81-583a656331db"
          }
        HEREDOC
        error = MailchimpMarketing::ApiError.new(status: 400, response_body: response_body)
        allow(mailchimp_client_lists).to receive(:set_list_member).and_raise(error)

        expected_log_message = {
          mailchimp_action: "subscribe",
          detail: "[FILTERED] is in a compliance state due to unsubscribe, bounce, or compliance review and cannot be subscribed.",
          instance: "ecc64220-55ff-d413-6c81-583a656331db",
          status: 400,
          subscriber_hash: "640f8c96cd7de424a8248a15d8b19b4d",
          task: "Mailchimp::ListSynchronizer#synchronize",
          title: "Member In Compliance State",
        }

        described_class.new(list_id: "list-1").synchronize(desired_members:)
        expect(Rails.logger).to have_received(:warn).with(expected_log_message)
      end

      it "logs the issue when the response_body is not available" do
        response_body = <<~HEREDOC
          this is not valid json
        HEREDOC
        error = MailchimpMarketing::ApiError.new(status: 400, response_body: response_body)
        allow(mailchimp_client_lists).to receive(:set_list_member).and_raise(error)

        expected_log_message = {
          mailchimp_action: "subscribe",
          detail: "Unparseable or empty response_body",
          instance: "unknown",
          status: 400,
          subscriber_hash: "640f8c96cd7de424a8248a15d8b19b4d",
          task: "Mailchimp::ListSynchronizer#synchronize",
          title: "Unknown error",
        }

        described_class.new(list_id: "list-1").synchronize(desired_members:)
        expect(Rails.logger).to have_received(:warn).with(expected_log_message)
      end
    end

    context "when member is new and role is set" do
      let(:list_1_members_info) { { "members" => [] } }
      let(:desired_members) { [Mailchimp::Member.new(email: "user@domain.org", status: "subscribed", role: "AGREED_MOU")] }

      it "updates the role" do
        expect(mailchimp_client_lists).to receive(:set_list_member).with(
          "list-1",
          anything,
          {
            "email_address" => "user@domain.org",
            "status" => "subscribed",
            "merge_fields" => {
              "ROLE" => "AGREED_MOU",
            },
          },
        )

        described_class.new(list_id: "list-1").synchronize(desired_members:)
      end
    end

    context "when member has different role and role is set" do
      let(:list_1_members_info) do
        { "members" => [{
          "email_address" => "user@domain.org",
          "status" => "subscribed",
          "merge_fields" => {
            "ROLE" => "ORGANISATION_ADMIN",
          },
        }] }
      end

      let(:desired_members) { [Mailchimp::Member.new(email: "user@domain.org", status: "subscribed", role: "AGREED_MOU")] }

      it "updates the role" do
        expect(mailchimp_client_lists).to receive(:set_list_member).with(
          "list-1",
          anything,
          {
            "email_address" => "user@domain.org",
            "status" => "subscribed",
            "merge_fields" => {
              "ROLE" => "AGREED_MOU",
            },
          },
        )

        described_class.new(list_id: "list-1").synchronize(desired_members:)
      end
    end

    context "when member has same role" do
      let(:list_1_members_info) do
        { "members" => [{
          "email_address" => "user@domain.org",
          "status" => "subscribed",
          "merge_fields" => {
            "ROLE" => "AGREED_MOU",
          },
        }] }
      end

      let(:desired_members) { [Mailchimp::Member.new(email: "user@domain.org", status: "subscribed", role: "AGREED_MOU")] }

      it "does not update role" do
        expect(mailchimp_client_lists).not_to receive(:set_list_member)
        described_class.new(list_id: "list-1").synchronize(desired_members:)
      end
    end

    context "when member has tag changes" do
      let(:list_1_members_info) do
        { "members" => [{
          "email_address" => "user@domain.org",
          "status" => "subscribed",
          "tags" => [{ "id" => 1, "name" => "old-tag" }],
        }] }
      end

      let(:desired_members) { [Mailchimp::Member.new(email: "user@domain.org", status: "subscribed", tags: [{ "name" => "old-tag", "status" => "inactive" }, { "name" => "new-tag", "status" => "active" }])] }

      it "updates the member with the new tags" do
        expect(mailchimp_client_lists).to receive(:update_list_member_tags).with(
          "list-1",
          anything,
          { "tags" => [
            { "name" => "old-tag", "status" => "inactive" },
            { "name" => "new-tag", "status" => "active" },
          ] },
        )

        described_class.new(list_id: "list-1").synchronize(desired_members:)
      end
    end

    context "when member has no tag changes" do
      let(:list_1_members_info) do
        { "members" => [{
          "email_address" => "user@domain.org",
          "status" => "subscribed",
          "tags" => [{ "id" => 1, "name" => "old-tag" }],
        }] }
      end

      let(:desired_members) { [Mailchimp::Member.new(email: "user@domain.org", status: "subscribed", tags: [])] }

      it "does not update the tags" do
        expect(mailchimp_client_lists).not_to receive(:update_list_member_tags)

        described_class.new(list_id: "list-1").synchronize(desired_members:)
      end
    end
  end
end
