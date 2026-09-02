FactoryBot.define do
  factory :organisation_domain do
    organisation { association :organisation }
    domain { Faker::Internet.unique.domain_name }
  end
end
