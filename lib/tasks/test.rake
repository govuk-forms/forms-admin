# frozen_string_literal: true

desc "Run tests, including accessibility (axe) checks"
task test: :environment do
  sh({ "RUN_AXE_TESTS" => "true" }, "bundle exec rspec")
  sh "npm run test"
end

namespace :test do
  desc "Run only the accessibility (axe) checks within the feature specs"
  task axe: :environment do
    sh({ "RUN_AXE_TESTS" => "true" }, "bundle exec rspec spec/features")
  end
end
