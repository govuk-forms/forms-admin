require "rails_helper"

RSpec.describe Analytics::FirehoseWriter do
  subject(:writer) { described_class.new("form-snapshots-test", client:) }

  let(:client) { Aws::Firehose::Client.new(stub_responses: true) }
  let(:rejected) { { error_code: "ServiceUnavailableException", error_message: "Slow down" } }

  def records_sent
    client.api_requests.map { |request| request[:params][:records].pluck(:data) }
  end

  before do
    allow(Kernel).to receive(:sleep)
  end

  it "puts each row as a JSON line, in batches of 500" do
    client.stub_responses(:put_record_batch, ->(context) { { failed_put_count: 0, request_responses: context.params[:records].map { { record_id: "1" } } } })

    writer.put(Array.new(501) { |index| { form_id: index.to_s } })

    expect(records_sent.map(&:size)).to eq [500, 1]
    expect(records_sent.last).to eq ["{\"form_id\":\"500\"}\n"]
  end

  it "retries only the rejected records" do
    client.stub_responses(:put_record_batch, [
      { failed_put_count: 1, request_responses: [{ record_id: "1" }, rejected] },
      { failed_put_count: 0, request_responses: [{ record_id: "2" }] },
    ])

    writer.put([{ form_id: "1" }, { form_id: "2" }])

    expect(records_sent.last).to eq ["{\"form_id\":\"2\"}\n"]
  end

  it "raises if records are still rejected after the last attempt" do
    client.stub_responses(:put_record_batch, { failed_put_count: 1, request_responses: [rejected] })

    expect { writer.put([{ form_id: "1" }]) }.to raise_error(described_class::Error, /rejected 1 records after 4 attempts/)
  end
end
