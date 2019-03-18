# frozen_string_literal: true

FactoryBot.define do
  factory :entry do
    kind          { Entry::DEPOSIT }
    amount        { Faker::Number.decimal(3, 2) }
    authorized_at { nil }
    sequence(:external_id) { |n| "ID_#{n}" }

    association :wallet, strategy: :random_or_create

    before(:create) do |entry|
      create(:entry_currency_rule,
             currency: entry.currency,
             kind: entry.kind,
             min_amount: 0,
             max_amount: entry.amount * 2)
    end
  end
end
