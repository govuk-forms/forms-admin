require "rails_helper"

RSpec.describe "groups.rake", type: :task do
  describe "groups:remove_group" do
    subject(:task) { Rake::Task["groups:remove_group"] }

    it "with correct arguments removes the group" do
      group = create(:group)

      expect {
        task.invoke(group.external_id)
      }.to change(Group, :count).by(-1)
    end

    it "with no arguments raises an error" do
      expect {
        task.invoke
      }.to raise_error(SystemExit)
      .and output(/usage/).to_stderr
    end

    it "with invalid group id raises an error" do
      invalid_args = %w[some_id_that_does_not_exist]
      expect {
        task.invoke(*invalid_args)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "with group that has forms raises an error" do
      group = create(:group)
      form = create(:form)
      group.group_forms.create!(form:)
      expect {
        task.invoke(group.external_id)
      }.to raise_error(SystemExit)
    end
  end

  describe "groups:remove_group_dry_run" do
    subject(:task) { Rake::Task["groups:remove_group_dry_run"] }

    it "with correct arguments does not remove the group" do
      group = create(:group)

      expect {
        task.invoke(group.external_id)
      }.not_to change(Group, :count)
    end
  end

  describe "groups:toggle_multiple_branches_enabled" do
    subject(:task) { Rake::Task["groups:toggle_multiple_branches_enabled"] }

    it "with correct arguments toggles multiple_branches_enabled for the group" do
      group = create(:group, multiple_branches_enabled: false)

      expect {
        task.invoke(group.external_id)
      }.to change { group.reload.multiple_branches_enabled }.from(false).to(true)
    end

    it "with no arguments raises an error" do
      expect {
        task.invoke
      }.to raise_error(SystemExit)
      .and output(/usage/).to_stderr
    end

    it "with invalid group id raises an error" do
      invalid_args = %w[some_id_that_does_not_exist]
      expect {
        task.invoke(*invalid_args)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
