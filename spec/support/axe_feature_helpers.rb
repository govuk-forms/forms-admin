module AxeFeatureHelpers
  def expect_page_to_have_no_axe_errors(page)
    return if skip_axe_tests?

    expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
  end

  def expect_component_to_have_no_axe_errors(page)
    return if skip_axe_tests?

    expect(page).to be_axe_clean.within("#main-content").according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
  end

private

  # Axe checks make feature specs significantly slower, so they can be skipped, e.g. for a
  # faster local test run. See Settings.skip_axe_tests in config/settings.yml.
  def skip_axe_tests?
    Settings.skip_axe_tests
  end
end

RSpec.configure do |config|
  config.include AxeFeatureHelpers, type: :feature
end
