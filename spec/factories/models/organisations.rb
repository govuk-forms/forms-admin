FactoryBot.define do
  factory :organisation do
    govuk_content_id { nil }
    sequence(:slug) { |n| "test-org-#{n}" }
    name { slug.titleize }
    abbreviation { name.split.collect(&:chr).join }
    internal { false }

    trait :with_signed_mou do
      after(:build) do |organisation|
        organisation.mou_signatures << build(:mou_signature_for_organisation, organisation:)
      end
    end

    trait :with_org_admin do
      with_signed_mou

      after(:build) do |organisation|
        organisation.users << build(:organisation_admin_user, organisation:)
      end
    end
  end
end
