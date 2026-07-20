require "rails_helper"

RSpec.describe "Create a form", type: :feature do
  let(:form) { create :form, name: "Test form", created_at: Faker::Time.backward }
  let(:unwanted_form) { create :form, name: "Test form", created_at: form.created_at + 0.1 }

  let(:group) do
    group = create :group, name: "Test group", creator: user, organisation: user.organisation
    create :membership, group:, user:, added_by: user
    group
  end

  let(:user) { standard_user }

  let(:javascript_enabled) { true }

  before do
    Capybara.current_driver = Settings.show_browser_during_tests ? :cuprite : :cuprite_headless

    page.driver.browser.disable_javascript unless javascript_enabled

    login_as user

    allow(Form).to receive(:create!).and_return form, unwanted_form
  end

  after do
    Capybara.use_default_driver
  end

  context "when a user double clicks on the button to create a new form" do
    before do
      visit group_path(group)
      click_on "Create a form"

      fill_in "What’s the name of your form?", with: form.name

      double_click find_button("Save and continue")
    end

    it "creates only one form" do
      expect(page).to have_title form.name
      expect(Form).to have_received(:create!).once
      expect(GroupForm.count).to eq 1
    end

    context "when javascript is disabled" do
      let(:javascript_enabled) { false }

      it "creates only one form" do
        expect(page).to have_title form.name
        expect(Form).to have_received(:create!).once
        expect(GroupForm.count).to eq 1
      end
    end
  end

  describe "deleting a group" do
    context "when a form has been created and then deleted in that group" do
      before do
        login_as_super_admin_user

        visit group_path(group)
        click_on "Create a form"

        fill_in "What’s the name of your form?", with: form.name

        click_on "Save and continue"

        click_on "Delete draft form"
        choose "Yes"
        click_on "Continue"
      end

      it "deletes the group" do
        click_on "Delete this group"
        choose "Yes"
        click_on "Continue"

        expect(page).to have_selector ".govuk-notification-banner--success", text: "The group, ‘Test group’, has been deleted"
      end
    end
  end

  # Element#double_click isn't working as expected in Ferrum
  # (see https://github.com/rubycdp/ferrum/issues/529),
  # so we need to reimplement it
  def double_click(element)
    node = element.base.node
    mouse = node.page.mouse

    x, y = node.find_position
    mouse.move(x:, y:)
    mouse.down
    mouse.up
    sleep(0.05)
    mouse.down
    mouse.up

    element
  end
end
