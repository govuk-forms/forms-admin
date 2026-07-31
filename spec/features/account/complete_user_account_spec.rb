require "rails_helper"

feature "Add account organisation to user without organisation", :feature_show_relevant_organisations, type: :feature do
  let(:domain) { "example.gov.uk" }
  let(:user) { create :user, :with_no_org, email: Faker::Internet.email(domain: domain), name: nil, terms_agreed_at: nil }
  let!(:organisation) { create :organisation, organisation_domains: [create(:organisation_domain, domain: domain)] }

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:auth0] = Faker::Omniauth.auth0(
      uid: user.uid,
      email: user.email,
    )

    allow(Settings).to receive(:auth_provider).and_return("auth0")

    # add another org so a list of options is displayed
    create :organisation, organisation_domains: [create(:organisation_domain, domain: domain)]
  end

  after do
    OmniAuth.config.mock_auth[:auth0] = nil
    OmniAuth.config.test_mode = false
  end

  scenario "when the user does not have an organisation or name, and hasn't agreed to the terms of use", type: :feature do
    when_i_visit_a_page_which_requires_sign_in
    then_i_should_be_redirected_to_the_account_organisation_page
    and_i_try_to_visit_the_homepage
    then_i_should_be_redirected_to_the_account_organisation_page
    and_i_select_an_organisation
    then_i_should_be_redirected_to_the_account_name_page
    and_i_fill_in_my_name
    then_i_should_be_redirected_to_the_account_terms_of_use_page
    and_i_agree_to_the_terms_of_use
    then_i_should_be_redirected_to_my_original_destination
  end

private

  def when_i_visit_a_page_which_requires_sign_in
    visit groups_path
  end

  def then_i_should_be_redirected_to_the_account_organisation_page
    expect(page).to have_content("Select your organisation")
  end

  def and_i_try_to_visit_the_homepage
    visit root_path
  end

  def and_i_select_an_organisation
    choose organisation.name_with_abbreviation
    click_button "Save and continue"
  end

  def then_i_should_be_redirected_to_the_account_name_page
    expect(page).to have_content("Enter your full name")
  end

  def then_i_should_be_redirected_to_the_account_terms_of_use_page
    expect(page).to have_content("Do you agree to these terms?")
  end

  def and_i_agree_to_the_terms_of_use
    check "I agree to these terms"
    click_button "Save and continue"
  end

  def and_i_fill_in_my_name
    fill_in "Enter your full name", with: "John Doe"
    click_button "Save and continue"
  end

  def then_i_should_be_redirected_to_my_original_destination
    expect(page).to have_current_path(groups_path)
  end
end
