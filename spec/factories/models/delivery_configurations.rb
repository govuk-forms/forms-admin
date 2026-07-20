FactoryBot.define do
  factory :delivery_configuration do
    association :form, factory: :form

    formats { [] }
    delivery_schedule { "immediate" }
    delivery_method { "email" }

    trait :immediate_email do
      delivery_schedule { "immediate" }
      delivery_method { "email" }
    end

    trait :batch_email do
      delivery_method { "email" }
      formats { %w[csv] }
    end

    trait :daily_email do
      batch_email
      delivery_schedule { "daily" }
    end

    trait :weekly_email do
      batch_email
      delivery_schedule { "weekly" }
    end

    trait :s3 do
      delivery_method { "s3" }
      formats { %w[csv] }
    end
  end
end
