FactoryBot.define do
  factory :organisation_domain do
    organisation { association :organisation }
    domain { Faker::Internet.domain_name }
  end
end
