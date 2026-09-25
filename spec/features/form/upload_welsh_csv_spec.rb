require "rails_helper"

feature "Upload a CSV of Welsh translations", type: :feature do
  let(:group) { create(:group, organisation: standard_user.organisation, status: "active") }
  let(:form) { create(:form, :with_pages, name: "My test form") }

  before do
    GroupForm.create!(group:, form_id: form.id)
    create(:membership, group:, user: standard_user, added_by: standard_user)

    login_as standard_user
  end

  scenario "upload a CSV of Welsh translations" do
    when_i_visit_the_welsh_translation_page
    and_i_click_the_upload_csv_link
    then_i_see_the_upload_page
    and_i_upload_a_valid_csv
    then_i_see_a_success_banner
    and_i_see_the_welsh_translation_form_prepopulated
    and_i_see_a_validation_error_for_invalid_welsh_input
  end

private

  def when_i_visit_the_welsh_translation_page
    visit welsh_translation_path(form)
    expect_page_to_have_no_axe_errors(page)
  end

  def and_i_click_the_upload_csv_link
    click_on "Upload new Welsh content as a CSV"
  end

  def then_i_see_the_upload_page
    expect(page.find("h1")).to have_text "Upload new Welsh content as a CSV"
    expect_page_to_have_no_axe_errors(page)
  end

  def and_i_upload_a_valid_csv
    csv_content = WelshCsvService.new(form).as_csv(include_bom: false)
    csv_with_welsh = add_welsh_translations(csv_content)

    file = Tempfile.new(["welsh_translations", ".csv"])
    file.write(csv_with_welsh)
    file.flush

    attach_file "Upload CSV file", file.path, make_visible: true
    click_button "Save and continue"
  ensure
    file&.close
    file&.unlink
  end

  def then_i_see_a_success_banner
    expect(page).to have_css ".govuk-notification-banner--success", text: "Your CSV has been uploaded"
  end

  def and_i_see_the_welsh_translation_form_prepopulated
    expect(page.find("h1")).to have_text "Add a Welsh version of your form"
    expect(page).to have_field("Enter your Welsh form name", with: "Welsh My test form")
  end

  def and_i_see_a_validation_error_for_invalid_welsh_input
    expect(page).to have_css ".govuk-error-summary", text: "Enter a link to Welsh privacy information in the correct format, like https://www.gov.uk/help/privacy-notice"
  end

  def add_welsh_translations(csv_content)
    rows = CSV.parse(csv_content)
    rows.map { |row|
      if row[0] == "Content ID"
        row
      else
        [row[0], row[1], "Welsh #{row[1]}"]
      end
    }.map(&:to_csv).join
  end
end
