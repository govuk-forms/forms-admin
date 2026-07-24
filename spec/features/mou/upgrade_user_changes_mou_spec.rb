require "rails_helper"

describe "Assign an organisation to a user with a signed MOU", type: :feature do
  let(:user) { create :user, name: "Test User", organisation: nil }
  let!(:mou_signature) { create(:mou_signature, user:, organisation: nil, created_at: Time.zone.parse("September 1, 2023")) }
  let!(:organisation) { create :organisation, slug: "department-for-testing" }

  it "assigning an organisation to a user adds it to their MOU" do
    login_as_super_admin_user
    when_i_update_the_user_organisation
    then_i_visit_the_organisation_page
    then_i_see_the_mou_with_organisation
  end

private

  def when_i_update_the_user_organisation
    visit edit_user_path(user)
    organisation_field = find_field "Organisation"
    # The \n is important, it "presses enter" to confirm the autocomplete selection
    organisation_field.fill_in with: "#{organisation.name}\n"
    expect(organisation_field.value).to start_with organisation.name
    click_button "Save"
    # wait for the save to finish before navigating away, or the form
    # submission's redirect can clobber the next page visit
    expect(page).to have_current_path(users_path)
  end

  def then_i_visit_the_organisation_page
    visit organisation_path(organisation)
  end

  def then_i_see_the_mou_with_organisation
    expect(page).to have_text "MOUs and agreements"
    expect(page).to have_text mou_signature.user.name
    expect(page).to have_link mou_signature.user.email
    expect(page).to have_text "September 01, 2023"
  end
end
