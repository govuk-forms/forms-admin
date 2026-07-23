require "rails_helper"

feature "View forms", type: :feature do
  let(:org_forms) { [build(:form, id: 1, name: "Org form")] }
  let(:other_org) { create :organisation, slug: "Other org" }
  let(:other_org_user) { create :user, organisation: other_org }
  let(:other_org_forms) { [build(:form, id: 2, name: "Other org form")] }
  let(:other_org_group) { create :group, organisation_id: other_org.id }

  before do
    # Orgs only show in the autocomplete if they have at least one user
    other_org_user
    other_org_group
    login_as_super_admin_user
  end

  scenario "Super admin can use autcomplete to view other org's groups" do
    visit root_path
    when_i_change_the_organisation
    then_i_should_see_the_groups_for_that_organisation
  end

  def when_i_change_the_organisation
    fill_in "search-organisation-id-field", with: other_org.name.to_s
    page.send_keys :enter
    click_button "Change"
  end

  def then_i_should_see_the_groups_for_that_organisation
    expect(page).to have_content(other_org_group.name)
  end
end
