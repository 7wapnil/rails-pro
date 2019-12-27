# frozen_string_literal: true

FactoryBot.define do
  factory :jackpot, class: EveryMatrix::Jackpot.name do
    base_currency_amount { rand(1..5) * 10_000 }
    sequence(:external_id, &:to_s)
  end
end
