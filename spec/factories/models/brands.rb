FactoryBot.define do
  factory :brand do
    sequence(:slug) { |n| "brand-#{n}" }
    name { slug.titleize }
    header_background_colour { "#ffffff" }
    border_colour { "#206c49" }
    logo_alt_text { name }
    logo_link { "https://www.#{slug}.example.com" }
    copyright_holder { name }
  end
end
