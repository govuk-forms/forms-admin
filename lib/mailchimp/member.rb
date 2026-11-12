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
  end
end
