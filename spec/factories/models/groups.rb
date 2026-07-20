FactoryBot.define do
  factory :group do
    sequence(:name) { |n| "Group #{n}" }
    organisation { association :organisation }
    creator { association :user, organisation: }
    status { :trial }
    external_id { SecureRandom.base58(8) }

    trait :org_has_org_admin do
      organisation { association :organisation, :with_org_admin }
    end
  end
end
