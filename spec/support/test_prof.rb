require "test_prof/recipes/rspec/let_it_be"
require "test_prof/recipes/rspec/factory_default"

TestProf::LetItBe.configure do |config|
  # Refind each record per example so in-memory mutation can't leak between examples
  config.default_modifiers[:refind] = true
end

TestProf::FactoryDefault.configure do |config|
  # Don't substitute the default record when traits or attribute overrides are given
  config.preserve_traits = true
  config.preserve_attributes = true
end
