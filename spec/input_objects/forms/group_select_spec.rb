require "rails_helper"

RSpec.describe Forms::GroupSelect, type: :model do
  let(:form) { create :form, id: 1, name: "Bye bye form", created_at: "2024-10-08T07:31:15.762Z" }
  let(:group) { build(:group, :org_has_org_admin) }
  let(:group_select) { described_class.new(group:, form:) }

  describe "groups" do
    it "returns groups" do
      create_list(:group, 3) do |g|
        g.organisation = group.organisation
        g.save!
      end

      expect(group_select.groups.count).to eq(3)
    end

    it "returns an empty array when there are no groups" do
      expect(group_select.groups).to be_empty
    end

    describe "filtered groups" do
      it "does not include the group that the form is currently in" do
        create_list(:group, 3) do |g|
          g.organisation = group.organisation
          g.save!
        end

        expect(group_select.groups.count).to be > 0
        expect(group_select.groups).not_to include(group)
      end

      context "when the organisation admin user is logged in" do
        it "returns only groups in the current group's organisation" do
          create_list(:group, 3, organisation: group.organisation)
          create(:group, organisation: build(:organisation)) # Group in a different organisation

          expect(group_select.groups).not_to include(group)
          expect(group_select.groups.count).to eq(3)
        end
      end

      context "when the form is live but the target group is trial" do
        it "returns only groups that are active" do
          form = build(:form, :live, id: 1)

          active_group = create(:group, name: "Active", status: :active, organisation: group.organisation)
          trial_group = create(:group, name: "Trial", status: :trial, organisation: group.organisation)

          group_select = described_class.new(group: group, form:)

          expect(group_select.groups).not_to include(trial_group)
          expect(group_select.groups).to include(active_group)
        end

        context "when the form is archived but the target group is trial" do
          it "returns groups that are active and trial" do
            form = build(:form, :archived, id: 1)

            active_group = create(:group, name: "Active", status: :active, organisation: group.organisation)
            trial_group = create(:group, name: "Trial", status: :trial, organisation: group.organisation)

            group_select = described_class.new(group: group, form:)

            expect(group_select.groups).to include(trial_group)
            expect(group_select.groups).to include(active_group)
          end
        end
      end
    end
  end

  it "is valid when a group is present" do
    group_select.group = build(:group)

    expect(group_select).to be_valid
  end

  it "is invalid if group is blank" do
    group_select.group = nil
    expect(group_select).to be_invalid
    expect(group_select.errors[:group]).to include("Select the group you want to move this form to")
  end
end
