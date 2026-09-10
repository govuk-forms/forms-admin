# frozen_string_literal: true

desc "Run tests, including accessibility (axe) checks unless Settings.skip_axe_tests is set"
task test: :environment do
  sh "bundle exec rspec"
  sh "npm run test"
end

namespace :test do
  desc "Run only the accessibility (axe) checks within the feature specs"
  task axe: :environment do
    sh({ "SETTINGS__SKIP_AXE_TESTS" => "false" }, "bundle exec rspec spec/features")
  end
end
