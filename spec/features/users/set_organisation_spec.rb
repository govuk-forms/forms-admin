require "rails_helper"

feature "Set or change a user's organisation", type: :feature do
  let!(:test_org) do
    create(:organisation, slug: "test-org")
  end

  before do
    create(:organisation, slug: "government-digital-service")
    create_list :user, 6, organisation: test_org
    login_as_super_admin_user
  end

  scenario "Super admin can change a user's organisation" do
    given_i_am_viewing_the_users_page
    and_i_choose_a_user_to_edit
    when_i_change_the_users_organisation
    then_the_users_organisation_name_is_updated
  end

private

  def given_i_am_viewing_the_users_page
    visit users_path
  end

  def and_i_choose_a_user_to_edit
    edit_user_path_re = %r{/users/(?<id>\d+)/edit}
    edit_user_link = page.find_all(:link, href: edit_user_path_re).sample
    @user = User.find(edit_user_path_re.match(edit_user_link[:href])[:id])

    edit_user_link.click
    expect(page).to have_css "h1.govuk-heading-l", text: "Edit user"
    expect(page).to have_text @user.name
  end

  def when_i_change_the_users_organisation
    @old_organisation_name = @user.organisation&.name || I18n.t("users.index.organisation_blank")
    @new_organisation_name = Organisation.pluck(:name).reject { |name| name == @old_organisation_name }.sample
    # The \n is important, it "presses enter"
    fill_in "Organisation", with: "#{@new_organisation_name}\n"
    click_button "Save"
  end

  def then_the_users_organisation_name_is_updated
    user_table_row = page.find(".govuk-table tr", text: @user.name)
    expect(user_table_row).to have_text @new_organisation_name
    expect(user_table_row).not_to have_text @old_organisation_name
  end
end
