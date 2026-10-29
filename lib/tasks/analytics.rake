# frozen_string_literal: true

namespace :analytics do
  desc "Put a snapshot of every form to the form snapshots Firehose stream, or print it if DRY_RUN=true"
  task snapshot_forms: :environment do
    # Build every row before sending any, so a bug in building them fails
    # before anything is written
    rows = Analytics::FormSnapshotService.new.rows
    stream_name = Settings.analytics.form_snapshots_stream_name

    if stream_name.blank? || ENV.fetch("DRY_RUN", nil) == "true"
      rows.each { |row| puts row.to_json }
      Rails.logger.info("Built #{rows.size} form snapshots without putting them to a stream")
    else
      Analytics::FirehoseWriter.new(stream_name).put(rows)
      Rails.logger.info("Put #{rows.size} form snapshots to #{stream_name}")
    end
  end
end
