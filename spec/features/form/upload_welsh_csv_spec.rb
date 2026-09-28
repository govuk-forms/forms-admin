require "rails_helper"

feature "Upload a CSV of Welsh translations", type: :feature do
  let(:group) { create(:group, organisation: standard_user.organisation, status: "active") }
  let(:form) do
    create(:form, :with_pages, name: "My test form", pages: [
      create(:page, :selection_with_autocomplete),
      create(:page),
    ])
  end
  let(:selection_options) { form.pages.first.answer_settings.selection_options }

  before do
    GroupForm.create!(group:, form_id: form.id)
    create(:membership, group:, user: standard_user, added_by: standard_user)

    login_as standard_user
  end

  scenario "upload a CSV of Welsh translations" do
    when_i_am_viewing_an_existing_form
    and_i_visit_the_welsh_translation_page
    and_i_do_not_see_inputs_for_the_selection_options_for_a_long_list
    and_i_click_the_upload_csv_link
    then_i_see_the_upload_page
    and_i_upload_a_valid_csv
    then_i_see_a_success_banner
    and_i_see_the_welsh_translation_form_prepopulated
    then_i_see_the_long_list_of_options_translations_in_a_details_component
    and_i_see_a_validation_error_for_invalid_welsh_input
    and_i_fix_the_validation_error
    and_i_save_the_translations
    when_i_revisit_the_welsh_translation_page
    then_i_see_the_long_list_of_options_translations_in_a_details_component
  end

private

  def when_i_am_viewing_an_existing_form
    visit form_path(form.id)
    expect_page_to_have_no_axe_errors(page)
  end

  def and_i_visit_the_welsh_translation_page
    click_on "Add a Welsh version of your form"
    expect(page.find("h1")).to have_text "Add a Welsh version of your form"
    expect_page_to_have_no_axe_errors(page)
  end

  def and_i_do_not_see_inputs_for_the_selection_options_for_a_long_list
    expect(page).to have_text(I18n.t("forms.welsh_translation.new.long_list_of_selection_options"))
    expect(page).not_to have_text("Enter Welsh option")
  end

  def and_i_click_the_upload_csv_link
    click_on "Upload Welsh content as a CSV"
  end

  def then_i_see_the_upload_page
    expect(page.find("h1")).to have_text "Upload new Welsh content as a CSV"
    expect(page).to have_css("input[type=file]", visible: :hidden)
    expect(page).to have_css("[data-module='govuk-file-upload']")
    expect_page_to_have_no_axe_errors(page)
  end

  def and_i_upload_a_valid_csv
    csv_content = WelshCsvService.new(form).as_csv(include_bom: false)
    csv_with_welsh = add_welsh_translations(csv_content)

    file = Tempfile.new(["welsh_translations", ".csv"])
    file.write(csv_with_welsh)
    file.flush

    attach_file file.path, make_visible: true
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

  def then_i_see_the_long_list_of_options_translations_in_a_details_component
    expect(page).to have_css("summary", text: I18n.t("forms.welsh_translation.new.selection_options_details_summary.english", count: selection_options.size))
    expect(page).to have_css("summary", text: I18n.t("forms.welsh_translation.new.selection_options_details_summary.welsh", count: selection_options.size))
    selection_options.each_with_index do |option, _index|
      expect(page).to have_css("li", text: option.name, visible: :hidden)
      expect(page).to have_css("li", text: "Welsh #{option.name}", visible: :hidden)

      # translations should be in hidden inputs
      expect(page).to have_css("input[type=hidden][value='Welsh #{option.name}']", visible: :all)
    end
  end

  def and_i_see_a_validation_error_for_invalid_welsh_input
    expect(page).to have_css ".govuk-error-summary", text: "Enter a link to Welsh privacy information in the correct format, like https://www.gov.uk/help/privacy-notice"
  end

  def and_i_fix_the_validation_error
    fill_in "Enter link to your Welsh privacy information", with: "https://www.gov.uk/help/privacy-notice-welsh", fill_options: { clear: :backspace }
  end

  def and_i_save_the_translations
    choose "Yes"
    click_button "Save and continue"
  end

  def then_i_am_redirected_to_the_task_list
    expect(page.find("h1")).to have_text "Edit your form"
  end

  def when_i_revisit_the_welsh_translation_page
    click_on "Add a Welsh version of your form"
    expect(page.find("h1")).to have_text "Add a Welsh version of your form"
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
