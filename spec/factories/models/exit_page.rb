FactoryBot.define do
  factory :exit_page, class: "ExitPage" do
    heading { Faker::Lorem.sentence }
    markdown { Faker::Lorem.paragraph }
    association :question_page, factory: :page
  end
end
