RSpec.configure do |config|
  config.define_derived_metadata(type: :feature) do |metadata|
    metadata[:slow] ||= true
  end
end
