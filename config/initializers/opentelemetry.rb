require "opentelemetry/sdk"
require "opentelemetry/instrumentation/all"
require "opentelemetry-metrics-sdk"
require "opentelemetry/exporter/otlp_metrics"

return unless ENV["ENABLE_OTEL"] == "true"

OpenTelemetry::SDK.configure do |c|
  instrumentation_config = { "OpenTelemetry::Instrumentation::Rack" => { untraced_endpoints: ["/up"] } }
  c.use_all(instrumentation_config)

  if ENV["OTEL_PROPAGATORS"] == "xray"
    # The ID Generator can only be configured through code. Gate it behind the propagator env var to keep things agnostic.
    c.id_generator = OpenTelemetry::Propagator::XRay::IDGenerator
  end

  # Disable logging for Rake tasks to avoid cluttering output
  c.logger = Logger.new(File::NULL) if Rails.const_defined?(:Rake) && Rake.application.top_level_tasks.any?
end

# Metrics are configured automatically by opentelemetry-metrics-sdk via OTEL_METRICS_EXPORTER
# (defaults to "otlp"), pushing to the collector sidecar at OTEL_EXPORTER_OTLP_ENDPOINT.
