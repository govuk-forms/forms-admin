require "rails_helper"

RSpec.describe "users.rake", type: :task do
  describe "users:delete_user_dry_run" do
    subject(:task) do
      Rake::Task["users:delete_user_dry_run"]
    end

    let!(:user_to_delete) { create(:user) }

    context "when a user ID is provided" do
      it "does not delete the user" do
        expect {
          task.invoke(user_to_delete.id)

          user_to_delete.reload
        }.not_to raise_error
      end

      it "logs the deletion and the rollback" do
        expect(Rails.logger).to receive(:info).with("Deleted user: #{user_to_delete.id}")
        expect(Rails.logger).to receive(:info).with("users:delete_user_dry_run: rollback deletion of user #{user_to_delete.id}")
        task.invoke(user_to_delete.id)
      end
    end

    context "when a user ID is not provided" do
      it "aborts with a usage message" do
        expect {
          task.invoke
        }.to raise_error(SystemExit)
        .and output("usage: rake delete_user_dry_run[<user_id>]\n").to_stderr
      end
    end
  end

  describe "users:delete_user" do
    subject(:task) do
      Rake::Task["users:delete_user"]
    end

    let!(:user_to_delete) { create(:user) }

    context "when a user ID is provided" do
      it "deletes the user" do
        expect {
          task.invoke(user_to_delete.id)

          user_to_delete.reload
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "logs the deletion" do
        expect(Rails.logger).to receive(:info).with("Deleted user: #{user_to_delete.id}")
        task.invoke(user_to_delete.id)
      end
    end

    context "when a user ID is not provided" do
      it "aborts with a usage message" do
        expect {
          task.invoke
        }.to raise_error(SystemExit)
        .and output("usage: rake delete_user[<user_id>]\n").to_stderr
      end
    end
  end

  describe "users:delete_users_with_no_name_or_org" do
    subject(:task) do
      Rake::Task["users:delete_users_with_no_name_or_org"]
    end

    let(:users) do
      [].concat(
        create_list(:user, 3, :old, :with_unique_email),
        create_list(:user, 3, :old, :with_no_name, :with_unique_email),
        create_list(:user, 3, :old, :with_no_org, :with_unique_email),
        create_list(:user, 3, :old, :with_no_name, :with_no_org, :with_unique_email),
      )
    end

    before do
      users
      allow(Rails.logger).to receive(:info)
    end

    it "deletes users with no name or organisation set" do
      expect {
        task.invoke
      }.to change(User, :count).to(3)
    end

    it "logs deleting each user" do
      task.invoke

      expect(Rails.logger).to have_received(:info).with(/delete_users_with_no_name_or_org: Deleted user \d+ \(.+@.+\)/).exactly(9)
    end

    it "logs the number of users deleted" do
      task.invoke

      expect(Rails.logger).to have_received(:info).with(/delete_users_with_no_name_or_org: Deleted 9 users/)
    end

    context "when the user has only just started using the service" do
      let!(:new_user) do
        users[8].update!(attributes_for(:user, :new, :with_no_org))
        users[8]
      end

      it "does not delete that user" do
        task.invoke

        expect(User.exists?(new_user.id)).to be true
      end

      it "deletes other users not in a group" do
        expect {
          task.invoke
        }.to change(User, :count).to(4)
      end

      it "logs that the user is being skipped" do
        task.invoke

        expect(Rails.logger).to have_received(:info).with(
          /delete_users_with_no_name_or_org: User could still have active session, skipping deleting user \d+/,
        )
      end

      it "counts the user as being skipped" do
        task.invoke

        expect(Rails.logger).to have_received(:info).with(
          /delete_users_with_no_name_or_org: Deleted 8 users, skipped deleting 1 users/,
        )
      end
    end

    context "when user is in one or more groups" do
      let(:user_in_group) { users.fifth }

      before do
        group = create :group, creator: users.first, organisation: user_in_group.organisation
        create :membership, group:, user: user_in_group, added_by: users.first
      end

      it "does not delete that user" do
        task.invoke

        expect(User.exists?(user_in_group.id)).to be true
      end

      it "deletes other users not in a group" do
        expect {
          task.invoke
        }.to change(User, :count).to(4)
      end

      it "logs that the user is being skipped" do
        task.invoke

        expect(Rails.logger).to have_received(:info).with(
          /delete_users_with_no_name_or_org: Found user in groups \[\d+\], skipping deleting user \d+/,
        )
      end

      it "counts the user as being skipped" do
        task.invoke

        expect(Rails.logger).to have_received(:info).with(
          /delete_users_with_no_name_or_org: Deleted 8 users, skipped deleting 1 users/,
        )
      end
    end

    describe ":dry_run" do
      subject(:dry_run_task) do
        Rake::Task["users:delete_users_with_no_name_or_org:dry_run"]
      end

      let(:user_in_group) { users.fifth }
      let(:group_with_user) { create :group, creator: users.first, organisation: user_in_group.organisation }

      before do
        create :membership, group: group_with_user, user: user_in_group, added_by: users.first
      end

      it "logs the changes that would be made" do
        dry_run_task.invoke

        [
          "users:delete_users_with_no_name_or_org:dry_run: Found 9 users without a name or organisation set",

          "users:delete_users_with_no_name_or_org:dry_run: Found user #{users[3].id} (#{users[3].email}) without a name or organisation set",
          "users:delete_users_with_no_name_or_org:dry_run: Deleted user #{users[3].id} (#{users[3].email})",

          "users:delete_users_with_no_name_or_org:dry_run: Found user #{user_in_group.id} (#{user_in_group.email}) without a name or organisation set",
          "users:delete_users_with_no_name_or_org:dry_run: Found user in groups [#{group_with_user.id}], skipping deleting user #{user_in_group.id} (#{user_in_group.email})",

          "users:delete_users_with_no_name_or_org:dry_run: Found user #{users[5].id} (#{users[5].email}) without a name or organisation set",
          "users:delete_users_with_no_name_or_org:dry_run: Deleted user #{users[5].id} (#{users[5].email})",

          "users:delete_users_with_no_name_or_org:dry_run: Found user #{users[6].id} (#{users[6].email}) without a name or organisation set",
          "users:delete_users_with_no_name_or_org:dry_run: Deleted user #{users[6].id} (#{users[6].email})",

          "users:delete_users_with_no_name_or_org:dry_run: Found user #{users[7].id} (#{users[7].email}) without a name or organisation set",
          "users:delete_users_with_no_name_or_org:dry_run: Deleted user #{users[7].id} (#{users[7].email})",

          "users:delete_users_with_no_name_or_org:dry_run: Found user #{users[8].id} (#{users[8].email}) without a name or organisation set",
          "users:delete_users_with_no_name_or_org:dry_run: Deleted user #{users[8].id} (#{users[8].email})",

          "users:delete_users_with_no_name_or_org:dry_run: Found user #{users[9].id} (#{users[9].email}) without a name or organisation set",
          "users:delete_users_with_no_name_or_org:dry_run: Deleted user #{users[9].id} (#{users[9].email})",

          "users:delete_users_with_no_name_or_org:dry_run: Deleted 8 users, skipped deleting 1 users",
          "users:delete_users_with_no_name_or_org:dry_run: Finished dry run, no changes persisted",
        ].each do |line|
          expect(Rails.logger).to have_received(:info).with(a_string_matching(line))
        end
      end

      it "does not delete any users" do
        expect {
          dry_run_task.invoke
        }.not_to change(User, :count)
      end
    end
  end
end
