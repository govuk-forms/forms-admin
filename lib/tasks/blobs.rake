# frozen_string_literal: true

namespace :blobs do
  desc "list all non-brand-asset blobs in the ActiveStorage database"
  task :list_non_brand, %i[start_date end_date] => :environment do |_, args|
    parsed_start_date = Date.parse(args[:start_date])
    parsed_end_date = Date.parse(args[:end_date])

    Rails.logger.info("Listing unattached blob rows created between between #{parsed_start_date} and #{parsed_end_date}")

    blobs = ActiveStorage::Blob.unattached
      .where(created_at: parsed_start_date..parsed_end_date)
      .where.not("key LIKE 'assets/%'")
    blobs.pluck(:id, :filename, :content_type, :key, :created_at).each { Rails.logger.info(it.to_json) }
  end

  desc "delete all non-brand-asset blobs in the ActiveStorage database"
  task :delete_non_brand, %i[start_date end_date] => :environment do |_, args|
    parsed_start_date = Date.parse(args[:start_date])
    parsed_end_date = Date.parse(args[:end_date])

    Rails.logger.info("Deleting unattached blob rows created between between #{parsed_start_date} and #{parsed_end_date}")

    blobs = ActiveStorage::Blob.unattached
      .where(created_at: parsed_start_date..parsed_end_date)
      .where.not("key LIKE 'assets/%'")

    deleted = blobs.each do |blob|
      Rails.logger.info("Purging blob with id: #{blob.id}")
      blob.purge
    end

    Rails.logger.info("#{deleted.count} blob(s) deleted")
  end
end
