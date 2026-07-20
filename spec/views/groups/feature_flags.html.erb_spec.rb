require "rails_helper"

RSpec.describe "groups/feature_flags", type: :view do
  let(:feature_flag) { Group.feature_flag_attributes.first }
  let(:other_feature_flag) { Group.feature_flag_attributes.second }

  let(:group) do
    create :group, name: "Name"
  end

  before do
    skip "no group feature flags are configured" if Group.feature_flag_attributes.empty?

    assign(:group, group)
    assign(:feature_flags_input, Groups::FeatureFlagsInput.new(group:).assign_group_values)
    render
  end

  it "contains the page heading" do
    expect(rendered).to have_css("h1", text: I18n.t("groups.feature_flags.title"))
  end

  it "renders the feature flags form posting to the update action" do
    assert_select "form[action=?][method=?]", feature_flags_group_path(group), "post" do
      assert_select "input[name=?]", "groups_feature_flags_input[#{feature_flag}]"
    end
  end

  it "includes a checkbox for each toggleable feature flag" do
    Group.feature_flag_attributes.each do |flag|
      expect(rendered).to have_field(I18n.t("groups.feature_flags.flags.#{flag}"))
    end
  end

  it "includes the group name as a caption" do
    expect(rendered).to have_css(".govuk-caption-l", text: group.name)
  end

  it "explains that flags cannot be turned off" do
    expect(rendered).to have_text(I18n.t("groups.feature_flags.hint"))
  end

  context "when a feature flag is already enabled" do
    let(:group) do
      create :group, name: "Name", feature_flag => true
    end

    it "renders the flag as checked and disabled so it cannot be turned off" do
      assert_select "input[type=checkbox][name=?][checked=checked][disabled=disabled]", "groups_feature_flags_input[#{feature_flag}]"
    end

    it "leaves flags that are off enabled and unchecked" do
      skip "fewer than two group feature flags are configured" if Group.feature_flag_attributes.size < 2

      assert_select "input[type=checkbox][name=?]:not([disabled])", "groups_feature_flags_input[#{other_feature_flag}]"
    end
  end
end
