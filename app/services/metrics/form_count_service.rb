module Metrics
  class FormCountService
    class ExportError < StandardError; end

    METRIC_NAME = "FormCount".freeze
    METER_NAME = "forms-admin".freeze
    METER_VERSION = "1.0".freeze
    UNKNOWN_ORG = "Unknown".freeze
    METRIC_STATES = %w[draft live archived].freeze

    def publish_form_counts
      metric_count = 0

      form_counts_by_org_and_state.each do |(org, state), count|
        form_count_gauge.record(count, attributes: metric_attributes(org:, state:))
        metric_count += 1
      end

      export_metrics!

      Rails.logger.info "Published #{metric_count} form count metrics via OpenTelemetry"
    rescue StandardError => e
      Sentry.capture_exception(e)
      raise
    end

  private

    def form_counts_by_org_and_state
      totals = counted_form_totals
      organisation_names.each { |org_name| ensure_all_metric_states(totals, org_name) }
      ensure_all_metric_states(totals, UNKNOWN_ORG) if totals.keys.any? { |(org, _state)| org == UNKNOWN_ORG }
      totals
    end

    def counted_form_totals
      counts_by_org_and_state = Form
        .where.not(state: :deleted)
        .left_joins(group_form: { group: :organisation })
        .group(Organisation.arel_table[:name], Form.arel_table[:state], Organisation.arel_table[:internal])
        .count

      counts_by_org_and_state.each_with_object(Hash.new(0)) do |((org_name, state, internal), count), totals|
        next if internal == true # Skip internal organisations for metrics

        totals[[org_name || UNKNOWN_ORG, metric_state(state)]] += count
      end
    end

    def organisation_names
      Organisation.where(internal: false).pluck(:name)
    end

    def ensure_all_metric_states(totals, org_name)
      METRIC_STATES.each { |state| totals[[org_name, state]] += 0 }
    end

    def metric_state(state)
      case state
      when "live", "live_with_draft" then "live"
      when "archived", "archived_with_draft" then "archived"
      when "draft" then "draft"
      end
    end

    def metric_attributes(org:, state:)
      {
        "Environment" => Settings.forms_env.downcase,
        "Org" => org,
        "State" => state,
      }
    end

    def form_count_gauge
      @form_count_gauge ||= meter.create_gauge(
        METRIC_NAME,
        unit: "1",
        description: "Count of forms grouped by organisation and state",
      )
    end

    def meter
      OpenTelemetry.meter_provider.meter(METER_NAME, version: METER_VERSION)
    end

    def export_metrics!
      return if OpenTelemetry.meter_provider.metric_readers.empty?

      result = OpenTelemetry.meter_provider.force_flush
      return if result == OpenTelemetry::SDK::Metrics::Export::SUCCESS

      raise ExportError, "OpenTelemetry metrics export failed with result code #{result}"
    end
  end
end
