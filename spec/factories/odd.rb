# frozen_string_literal: true

FactoryBot.define do
  factory :odd do
    name                   { 'MiTH' }
    won                    { true }
    value                  { Faker::Number.decimal(1, 2) }
    status                 { Odd::INACTIVE }

    sequence(:external_id) { |n| "sr:match:#{n}:#{rand(0..10_000)}/hcp=0.5:#{n}" }

    market

    trait :active do
      status { Odd::ACTIVE }
    end
  end
end
