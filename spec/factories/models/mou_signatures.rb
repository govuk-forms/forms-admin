FactoryBot.define do
  factory :mou_signature do
    user { build(:user) }
    organisation { user.organisation }
    agreement_type { :crown }
    created_at { Time.zone.now }

    factory :mou_signature_for_organisation do
      organisation
      user { build(:user, organisation:) }
    end
  end
end
