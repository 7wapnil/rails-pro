# frozen_string_literal: true

FactoryBot.define do
  factory :odd do
    name       { 'MiTH' }
    won        { true }
    value      { Faker::Number.decimal(1, 2).to_f + 1 }
    status     { Odd::INACTIVE }
    outcome_id { '' }

    sequence(:external_id) do |n|
      "sr:match:#{n}:#{rand(0..10_000)}/hcp=0.5:#{n}"
    end

    association :market, strategy: :build

    Odd.statuses.keys.each do |status|
      trait(status.to_sym) do
        status { status }
      end
    end
  end
end
