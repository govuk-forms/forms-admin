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

  describe "groups:toggle_feature_flag" do
    subject(:task) { Rake::Task["groups:toggle_feature_flag"] }

    let(:feature_flag) { Group.feature_flag_attributes.first }
    let(:feature_name) { feature_flag.delete_suffix("_enabled") }

    before do
      skip "no group feature flags are configured" if Group.feature_flag_attributes.empty?
    end

    it "with correct arguments toggles the feature flag on for the group" do
      group = create(:group, feature_flag => false)

      expect {
        task.invoke(feature_name, group.external_id)
      }.to change { group.reload.send(feature_flag) }.from(false).to(true)
    end

    it "with correct arguments toggles the feature flag off for the group" do
      group = create(:group, feature_flag => true)

      expect {
        task.invoke(feature_name, group.external_id)
      }.to change { group.reload.send(feature_flag) }.from(true).to(false)
    end

    it "with no arguments raises an error" do
      expect {
        task.invoke
      }.to raise_error(SystemExit)
      .and output(/usage/).to_stderr
    end

    it "with no group id raises an error" do
      expect {
        task.invoke(feature_name)
      }.to raise_error(SystemExit)
      .and output(/usage/).to_stderr
    end

    it "with an unknown feature name lists the valid feature flags" do
      group = create(:group)

      expect {
        task.invoke("not_a_feature", group.external_id)
      }.to raise_error(SystemExit)
      .and output(/unknown feature flag: not_a_feature. Valid feature flags: .*#{feature_name}/).to_stderr
    end

    it "with invalid group id raises an error" do
      expect {
        task.invoke(feature_name, "some_id_that_does_not_exist")
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
