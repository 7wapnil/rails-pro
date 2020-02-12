# frozen_string_literal: true

FactoryBot.define do
  factory :label do
    sequence(:name)        { |n| "My label #{n}" }
    sequence(:description) { |n| "#{Faker::Community.quotes} #{n}" }

    trait :negative_balance do
      to_create { |instance| instance.save(validate: false) }

      keyword { Label::NEGATIVE_BALANCE }
      kind { Label::CUSTOMER }
      system { true }
    end
  end
end
