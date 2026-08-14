# frozen_string_literal: true

namespace :mailchimp do
  desc "Synchronise Mailchimp audiences with the users in the database"
  task synchronize_audiences: :environment do
    Mailchimp::ListSyncService.new.synchronize_lists
  end
end
