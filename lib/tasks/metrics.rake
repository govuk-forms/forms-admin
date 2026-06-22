namespace :metrics do
  desc "Export form counts as OpenTelemetry metrics grouped by organisation and state"
  task export_form_counts: :environment do
    Metrics::FormCountService.new.publish_form_counts
  end
end
