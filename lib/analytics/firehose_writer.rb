class Analytics::FirehoseWriter
  class Error < StandardError; end

  REGION = "eu-west-2".freeze

  # PutRecordBatch accepts at most 500 records per call
  BATCH_SIZE = 500
  MAX_ATTEMPTS = 4
  BASE_DELAY_SECONDS = 0.5

  attr_reader :stream_name, :client

  def initialize(stream_name, client: Aws::Firehose::Client.new(region: REGION))
    @stream_name = stream_name
    @client = client
  end

  # Firehose's Iceberg destination accepts only one JSON object per record, so
  # each row is put as its own record
  def put(rows)
    rows.map { |row| { data: "#{row.to_json}\n" } }
        .each_slice(BATCH_SIZE) { |records| put_batch(records) }
  end

private

  # Firehose can reject some records in a batch and accept the rest, so only
  # the rejected records are sent again
  def put_batch(records)
    (1..MAX_ATTEMPTS).each do |attempt|
      response = client.put_record_batch(delivery_stream_name: stream_name, records:)
      failed = records.zip(response.request_responses).select { |_record, result| result.error_code.present? }
      break if failed.empty?

      if attempt == MAX_ATTEMPTS
        errors = failed.map { |_record, result| result.error_code }.uniq
        raise Error, "#{stream_name} rejected #{failed.size} records after #{MAX_ATTEMPTS} attempts: #{errors.join(', ')}"
      end

      records = failed.map(&:first)
      Kernel.sleep(BASE_DELAY_SECONDS * (2**(attempt - 1)))
    end
  end
end
