FactoryBot.define do
  factory :form_document do
    form { association :form }
    tag { "draft" }
    version { nil }

    trait :live do
      tag { "live" }
      version { 1 }
    end

    trait :archived do
      tag { "archived" }
      version { 1 }
    end

    trait :draft do
      tag { "draft" }
    end
  end
end
