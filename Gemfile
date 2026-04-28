source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby file: ".ruby-version"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.6"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 8.0.0"

# Used for handling authentication
gem "gds-sso"
gem "omniauth-auth0"
gem "omniauth-rails_csrf_protection"
gem "warden"

# Used for handling authorisation policies
gem "pundit"

# Use Sentry (https://sentry.io/for/ruby/?platform=sentry.ruby.rails#)
gem "sentry-rails", "~> 6"
gem "sentry-ruby", "~> 6"

gem "config"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo"
gem "tzinfo-data"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# For compiling our frontend assets
gem "vite_rails"

# For GOV.UK branding
gem "govuk-components", "~> 6"
gem "govuk_design_system_formbuilder", "~> 6"

# The autocomplete component is not currently published as a gem, if changing
# the hash, also change in package.json
gem "dfe-autocomplete", require: "dfe/autocomplete", github: "DFE-Digital/dfe-autocomplete", ref: "1d4cc65039e11cc3ba9e7217a719b8128d0e4d53"

# Our own custom markdown renderer
gem "govuk-forms-markdown", require: "govuk_forms_markdown", github: "govuk-forms/govuk-forms-markdown", tag: "0.8.0"

# For structured logging
gem "lograge"

# For distributed tracing and telemetry
gem "opentelemetry-exporter-otlp", "~> 0.33.0"
gem "opentelemetry-instrumentation-all", "~> 0.92.0"
gem "opentelemetry-propagator-xray", "~> 0.26.1"
gem "opentelemetry-sdk", "~> 1.11"

# Use GOV.UK Nofity api to send emails
gem "govuk_notify_rails"

# Use validate_url so we don't have to write custom URL validation
gem "validate_url"

# For auditing tables
gem "paper_trail"

# For AWS interactions
gem "aws-sdk-cloudwatch", "~> 1.133"
gem "aws-sdk-codepipeline", "~> 1.113"

# For Mailchimp audience integration
gem "MailchimpMarketing", "~> 3.0"

# For generating CSV reports
gem "csv"

# Used for sorting/ordering of pages object
gem "acts_as_list"

# Add state machine for forms
gem "aasm", "~> 5.5"
# Used by AASM to autocommit state changes when even method is used with bang eg. make_live!
gem "after_commit_everywhere", "~> 1.6"

# For pagination
gem "pagy"

# IDNA conversion needed for validating email addresses
gem "uri-idna"

# For converting HTML to Markdown
gem "reverse_markdown"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  gem "factory_bot_rails"
  gem "faker"

  gem "i18n-tasks", "~> 1.1.2"
  gem "rails-controller-testing"
  gem "rspec-rails", ">= 3.9.0"
  gem "rubocop-govuk", require: false

  # For security auditing gem vulnerabilities. RUN IN CI
  gem "bundler-audit", "~> 0.9.3"

  # For detecting security vulnerabilities in Ruby on Rails applications via static analysis.
  gem "brakeman", "~> 8.0.4"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "cuprite"
  gem "selenium-webdriver"

  gem "pundit-matchers"

  # Code coverage reporter
  gem "simplecov", "~> 0.22.0", require: false

  gem "webmock"

  # axe-core for running automated accessibility checks
  gem "axe-core-rspec"

  gem "spring-commands-rspec"

  # Enable running the specs in parallel (and optionally with Spring)
  gem "parallel_rspec"
  gem "spring-prspec"
end

gem "mobility", "~> 1.3"
