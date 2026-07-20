FactoryBot.define do
  factory :membership do
    user { build :user }
    group { build :group, organisation: user&.organisation }
    added_by { build :user, organisation: user&.organisation }
    role { :editor }
  end
end
