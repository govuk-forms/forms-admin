require "rails_helper"
require "opentelemetry-metrics-sdk"

describe Metrics::FormCountService do
  subject(:service) { described_class.new }

  let(:forms_env) { "test" }
  let(:metric_exporter) { OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new }
  let(:organisation) { create(:organisation, name: "Department for Testing") }
  let(:group) { create(:group, organisation:) }
  let!(:original_meter_provider) { OpenTelemetry.meter_provider }

  before do
    allow(Settings).to receive(:forms_env).and_return(forms_env)

    provider = OpenTelemetry::SDK::Metrics::MeterProvider.new
    periodic_reader = OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader.new(
      export_interval_millis: 60_000,
      exporter: metric_exporter,
    )
    provider.add_metric_reader(periodic_reader)
    OpenTelemetry.meter_provider = provider
  end

  after do
    OpenTelemetry.meter_provider.shutdown
    OpenTelemetry.meter_provider = original_meter_provider
  end

  around do |example|
    travel_to(Time.zone.local(2026, 6, 3, 12, 0, 0)) do
      example.run
    end
  end

  describe "#publish_form_counts" do
    before do
      Form.destroy_all

      # Use explicit states instead of :live/:archived traits — those pull in :with_pages,
      # and each page factory creates its own :form, inflating counts.
      create(:form, :with_group, group:, state: :draft)
      create(:form, :with_group, group:, state: :live, pages: [])
      create(:form, :with_group, group:, state: :live_with_draft, pages: [])
      create(:form, :with_group, group:, state: :archived, pages: [])
      create(:form, :with_group, group:, state: :archived_with_draft, pages: [])
      create(:form, state: :draft)
    end

    it "publishes grouped form counts via OpenTelemetry" do
      service.publish_form_counts

      expect(exported_data_points).to contain_exactly(
        metric_data_point(org: organisation.name, state: "draft", count: 1),
        metric_data_point(org: organisation.name, state: "live", count: 2),
        metric_data_point(org: organisation.name, state: "archived", count: 2),
        metric_data_point(org: "Unknown", state: "draft", count: 1),
        metric_data_point(org: "Unknown", state: "live", count: 0),
        metric_data_point(org: "Unknown", state: "archived", count: 0),
      )
    end

    context "when an organisation has no forms" do
      let(:empty_organisation) { create(:organisation, name: "Empty Org", slug: "empty-org") }

      before { empty_organisation }

      it "publishes zero counts for each state" do
        service.publish_form_counts

        expect(exported_data_points).to contain_exactly(
          metric_data_point(org: organisation.name, state: "draft", count: 1),
          metric_data_point(org: organisation.name, state: "live", count: 2),
          metric_data_point(org: organisation.name, state: "archived", count: 2),
          metric_data_point(org: empty_organisation.name, state: "draft", count: 0),
          metric_data_point(org: empty_organisation.name, state: "live", count: 0),
          metric_data_point(org: empty_organisation.name, state: "archived", count: 0),
          metric_data_point(org: "Unknown", state: "draft", count: 1),
          metric_data_point(org: "Unknown", state: "live", count: 0),
          metric_data_point(org: "Unknown", state: "archived", count: 0),
        )
      end
    end

    context "when an organisation is internal" do
      let(:internal_organisation) { create(:organisation, name: "Internal Org", slug: "internal-org", internal: true) }
      let(:internal_group) { create(:group, organisation: internal_organisation) }

      before do
        create(:form, :with_group, group: internal_group, state: :draft)
        create(:form, :with_group, group: internal_group, state: :live, pages: [])
      end

      it "excludes forms belonging to internal organisations" do
        service.publish_form_counts

        expect(exported_data_points).to contain_exactly(
          metric_data_point(org: organisation.name, state: "draft", count: 1),
          metric_data_point(org: organisation.name, state: "live", count: 2),
          metric_data_point(org: organisation.name, state: "archived", count: 2),
          metric_data_point(org: "Unknown", state: "draft", count: 1),
          metric_data_point(org: "Unknown", state: "live", count: 0),
          metric_data_point(org: "Unknown", state: "archived", count: 0),
        )
      end
    end

    context "when OpenTelemetry export fails" do
      before do
        allow(OpenTelemetry.meter_provider).to receive(:force_flush)
          .and_return(OpenTelemetry::SDK::Metrics::Export::FAILURE)
      end

      it "captures the exception and re-raises" do
        expect(Sentry).to receive(:capture_exception).with(instance_of(Metrics::FormCountService::ExportError))

        expect { service.publish_form_counts }.to raise_error(Metrics::FormCountService::ExportError)
      end
    end
  end

  def exported_data_points
    metric_exporter.metric_snapshots.flat_map(&:data_points)
  end

  def metric_data_point(org:, state:, count:)
    have_attributes(
      attributes: {
        "Environment" => forms_env,
        "Org" => org,
        "State" => state,
      },
      value: count,
    )
  end
end
