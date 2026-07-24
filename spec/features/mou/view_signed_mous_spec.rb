require "rails_helper"

describe "Check which MOUs have been signed", type: :feature do
  let(:organisation) { create :organisation, slug: "department-for-testing" }
  let!(:mou_signature) { create(:mou_signature_for_organisation, organisation:, created_at: Time.zone.parse("October 12, 2023")) }

  before do
    login_as_super_admin_user
  end

  it "super_admin's can see an organisation's signed MOUs" do
    then_i_click_on_the_organisations_link
    then_i_click_on_the_organisation
    then_i_can_see_the_mou_list
  end

private

  def then_i_click_on_the_organisations_link
    visit root_path
    click_link("Organisations")
  end

  def then_i_click_on_the_organisation
    click_link organisation.name_with_abbreviation
  end

  def then_i_can_see_the_mou_list
    expect(page).to have_text "MOUs and agreements"
    expect(page).to have_text "Crown MOU"
    expect(page).to have_text mou_signature.user.name
    expect(page).to have_link mou_signature.user.email
    expect(page).to have_text "October 12, 2023"
  end
end
