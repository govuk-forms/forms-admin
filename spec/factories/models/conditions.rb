FactoryBot.define do
  factory :condition, class: "Condition" do
    transient do
      form { build(:form) }
    end

    routing_page { association :page, form: }
    check_page { nil }
    goto_page { nil }
    answer_value { nil }
    skip_to_end { false }
    exit_page_heading { nil }
    exit_page_markdown { nil }

    trait :with_exit_page do
      goto_page { nil }
      exit_page_heading { "Exit page heading" }
      exit_page_markdown { "Exit page markdown" }
    end
  end
end
