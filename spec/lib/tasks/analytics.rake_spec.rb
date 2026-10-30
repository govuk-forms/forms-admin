require "rails_helper"

RSpec.describe "analytics.rake", type: :task do
  describe "analytics:snapshot_forms" do
    subject(:task) do
      Rake::Task["analytics:snapshot_forms"]
    end

    let(:rows) { [{ form_id: "1", state: "live" }] }
    let(:firehose_writer) { instance_double(Analytics::FirehoseWriter, put: nil) }

    before do
      allow(Analytics::FormSnapshotService).to receive(:new).and_return(instance_double(Analytics::FormSnapshotService, rows:))
      allow(Analytics::FirehoseWriter).to receive(:new).with("form-snapshots-test").and_return(firehose_writer)
    end

    it "puts the rows to the form snapshots stream" do
      allow(Settings.analytics).to receive(:form_snapshots_stream_name).and_return("form-snapshots-test")

      task.invoke

      expect(firehose_writer).to have_received(:put).with(rows)
    end

    it "prints the rows when there is no stream name" do
      expect { task.invoke }.to output("{\"form_id\":\"1\",\"state\":\"live\"}\n").to_stdout

      expect(firehose_writer).not_to have_received(:put)
    end
  end
end
