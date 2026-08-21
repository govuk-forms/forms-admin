require "rails_helper"

describe "Add a new domain to an organisation" do
  let(:organisation) { create(:organisation) }

  it "adds the domain to an organisation page" do
    login_as_super_admin_user
    when_i_click_on_the_add_a_domain_button
    and_i_add_a_domain
    and_i_visit_the_organisation_page
    then_i_see_the_new_domain_listed
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
end
