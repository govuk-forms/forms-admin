module Mailchimp
  Member = Data.define(:email, :status, :role, :tags) do
    def initialize(email:, status:, role: nil, tags: []) = super

    def unsubscribed?
      status == "unsubscribed"
    end

    def archivable?
      %w[subscribed cleaned pending transactional].include?(status)
    end

    def subscriber_hash
      Digest::MD5.hexdigest email.downcase
    end

    def active_tags
      tags.filter { it["status"] == "active" }.map { it["name"] }
    end

    def inactive_tags
      tags.filter { it["status"] == "inactive" }.map { it["name"] }
    end
  end
end
