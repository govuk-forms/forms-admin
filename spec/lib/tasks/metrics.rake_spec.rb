require "rails_helper"

RSpec.describe "metrics.rake", type: :task do
  describe "metrics:export_form_counts" do
    subject(:task) do
      Rake::Task["metrics:export_form_counts"]
    end

    it "publishes form counts via Metrics::FormCountService" do
      service = instance_double(Metrics::FormCountService)
      allow(Metrics::FormCountService).to receive(:new).and_return(service)
      expect(service).to receive(:publish_form_counts)

      task.invoke
    end
  end
end
