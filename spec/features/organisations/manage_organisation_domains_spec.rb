require "rails_helper"

describe "Add a new domain to an organisation" do
  let(:organisation) { create(:organisation) }

  it "adds the domain to an organisation page" do
    login_as_super_admin_user
    when_i_click_on_the_add_a_domain_button
    and_i_add_a_domain
    and_i_visit_the_organisation_page
    then_i_see_the_new_domain_listed
    and_there_is_a_remove_button_for_domains
    when_i_click_on_the_remove_domain_button
    then_i_confirm
    i_no_longer_see_the_domain_for_the_organisation
  end

private

  def when_i_click_on_the_add_a_domain_button
    visit organisation_path(organisation)
    click_link "Add a domain"
  end

  def and_i_add_a_domain
    domain_field = find_field "Domain"
    domain_field.fill_in with: "example.com"
    expect(domain_field.value).to eq "example.com"
    click_button "Add domain"
    expect(page).to have_content "example.com has been added"
  end

  def and_i_visit_the_organisation_page
    visit organisation_path(organisation)
  end

  def then_i_see_the_new_domain_listed
    expect(page).to have_content "example.com"
  end

  def and_there_is_a_remove_button_for_domains
    expect(page).to have_link "Remove"
  end

  def when_i_click_on_the_remove_domain_button
    click_link "Remove"
  end

  def then_i_confirm
    expect(page).to have_content "Are you sure you want to remove example.com from this organisation?"
    choose "Yes"
    click_button "Continue"
    expect(page).to have_content "example.com has been removed from this organisation"
  end

  def i_no_longer_see_the_domain_for_the_organisation
    visit organisation_path(organisation)
    expect(page).not_to have_content "example.com"
  end
end
