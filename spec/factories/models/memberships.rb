FactoryBot.define do
  factory :membership do
    user { association :user }
    group { association :group, organisation: user&.organisation, creator: user }
    added_by { association :user, organisation: user&.organisation }
    role { :editor }
  end
end
