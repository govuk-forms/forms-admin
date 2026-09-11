module AxeFeatureHelpers
  def expect_page_to_have_no_axe_errors(page)
    return unless run_axe_tests?

    expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
  end

  def expect_component_to_have_no_axe_errors(page)
    return unless run_axe_tests?

    expect(page).to be_axe_clean.within("#main-content").according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
  end

private

  # Axe checks make feature specs significantly slower, so they only run when
  # explicitly requested, e.g. via `rake test` or `rake test:axe`, rather than
  # on every plain `rspec` run.
  def run_axe_tests?
    ActiveModel::Type::Boolean.new.cast(ENV["RUN_AXE_TESTS"])
  end
end

RSpec.configure do |config|
  config.include AxeFeatureHelpers, type: :feature
end
