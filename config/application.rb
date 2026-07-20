require_relative "boot"

require "rails/all"

require "./app/lib/hosting_environment"
require "./app/lib/json_log_formatter"
require "./app/lib/application_logger"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FormsAdmin
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks warden generators notifications_utils])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.exceptions_app = routes

    config.action_dispatch.rescue_responses["NotFoundError"] = :not_found

    # All forms should use GOVUKDesignSystemFormBuilder by default
    config.action_view.default_form_builder = GOVUKDesignSystemFormBuilder::FormBuilder

    # Make it easier to share partials between controllers
    config.action_view.prefix_partial_path_with_controller_namespace = false

    config.view_component.previews.paths = [Rails.root.join("spec/components")]
    config.view_component.previews.route = "/preview"
    config.view_component.previews.controller = "ComponentPreviewController"
    # Replace with value which will be true in local dev
    config.view_component.show_previews = HostingEnvironment.test_environment?

    ### LOGGING CONFIGURATION ###
    config.log_level = :info

    # Lograge is used to format the standard HTTP request logging
    config.lograge.enabled = true
    config.lograge.formatter = Lograge::Formatters::Json.new
    config.lograge.logger = ActiveSupport::Logger.new($stdout)

    # Lograge suppresses the default Rails request logging. Set this to true to
    #  make lograge output it which includes some extra debugging
    # information.
    config.lograge.keep_original_rails_log = false

    config.lograge.custom_options = lambda do |event|
      CurrentLoggingAttributes.attributes.merge(
        exception: event.payload[:exception],
        queries_count: event.payload[:queries_count],
        cached_queries_count: event.payload[:cached_queries_count],
      ).compact
    end

    # Use custom logger and formatter to log in JSON with request context fields. To use conventional
    # logging use ActiveSupport::Logger.new($stdout).
    config.logger = ApplicationLogger.new($stdout)
    config.logger.formatter = JsonLogFormatter.new

    # Prevent ActiveRecord::PreparedStatementCacheExpired errors when adding columns
    config.active_record.enumerate_columns_in_select_statements = true

    # Include full precision of timestamps in JSON responses
    config.active_support.time_precision = 6

    # Turn off image variant processing since we're not currently generating image variants
    config.active_storage.variant_processor = :disabled

    # Turn off locale enforcement - this allows us to use locales
    # in Mobility without enabling those languages for the admin UI
    I18n.enforce_available_locales = false
  end
end
