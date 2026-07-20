class DeliveryConfiguration < ApplicationRecord
  belongs_to :form

  FORMATS = %w[csv json].freeze

  enum :delivery_schedule, {
    immediate: "immediate",
    daily: "daily",
    weekly: "weekly",
  }

  enum :delivery_method, {
    email: "email",
    s3: "s3",
  }

  validates :formats, inclusion: { in: FORMATS }

  def as_json(options = {})
    options[:only] ||= %i[delivery_method formats delivery_schedule]
    super(options)
  end
end
