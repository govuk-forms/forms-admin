FactoryBot.define do
  factory :brand do
    sequence(:slug) { |n| "brand-#{n}" }
    name { slug.titleize }
  end
end
