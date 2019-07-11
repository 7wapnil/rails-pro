# frozen_string_literal: true

FactoryBot.define do
  factory :balance_entry do
    amount { Faker::Number.decimal(3, 2) }

    entry
    association :balance, strategy: :build

    Balance.kinds.keys.map(&:to_sym).each do |kind|
      trait kind do
        association :balance, factory: [:balance, kind], strategy: :build
      end
    end
  end
end
