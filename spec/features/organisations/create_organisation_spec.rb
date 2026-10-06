require "rails_helper"

describe "Add a new organisation" do
  it "shows errors for blank fields then creates the organisation successfully" do
    login_as_super_admin_user
    when_i_visit_the_organisations_page
    and_i_click_add_an_organisation
    and_i_submit_the_blank_form
    then_i_see_errors_for_both_fields
    when_i_fill_in_the_form
    then_i_am_redirected_to_the_show_page_with_a_success_message
  end

private

  def when_i_visit_the_organisations_page
    visit organisations_path
  end

  def and_i_click_add_an_organisation
    click_link "Add an organisation"
  end

  def and_i_submit_the_blank_form
    click_button "Save and continue"
  end

  def then_i_see_errors_for_both_fields
    expect(page).to have_content("Enter an organisation name")
    expect(page).to have_content("Enter a domain name")
  end

  def when_i_fill_in_the_form
    fill_in "Organisation name", with: "Test Organisation"
    fill_in "Email domain", with: "test-organisation.gov.uk"
    click_button "Save and continue"
  end

  def then_i_am_redirected_to_the_show_page_with_a_success_message
    expect(page).to have_current_path(organisation_path(Organisation.last))
    expect(page).to have_content("Test Organisation has been added")
  end
end
