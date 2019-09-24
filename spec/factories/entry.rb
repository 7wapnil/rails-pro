# frozen_string_literal: true

FactoryBot.define do
  factory :entry do
    kind          { Entry::DEPOSIT }
    amount        { Faker::Number.decimal(4, 2) }
    base_currency_amount { Faker::Number.decimal(4, 2) }
    authorized_at { nil }
    sequence(:external_id) { |n| "ID_#{n}" }

    wallet
    entry_request

    before(:create) do |entry|
      create(:entry_currency_rule,
             currency: entry.currency,
             kind: entry.kind,
             min_amount: -entry.amount.abs * 2,
             max_amount: entry.amount.abs * 2)
    end

    trait :confirmed do
      confirmed_at { Time.zone.now }
    end

    trait :with_random_wallet do
      association :wallet, strategy: :random_or_create
    end

    trait :recent do
      created_at { Date.current.yesterday.midday }
    end

    trait :with_bonus_balances do
      bonus_amount { Faker::Number.decimal(2, 2) }
    end

    trait :with_bonus_balance_entry do
      after(:create) do |entry|
        entry.update(bonus_amount: entry.amount)
      end
    end

    trait :with_real_money_balance_entry do
      after(:create) do |entry|
        entry.update(real_money_amount: entry.amount)
      end
    end

    trait :with_balance_entries do
      after(:create) do |entry|
        entry.update(
          real_money_amount: entry.amount / 2,
          bonus_amount: entry.amount / 2
        )
      end
    end

    EntryKinds::DEBIT_KINDS.each do |kind|
      trait(kind.to_sym) do
        kind { kind }
      end
    end

    EntryKinds::CREDIT_KINDS.each do |kind|
      trait(kind.to_sym) do
        kind { kind }
        amount { Faker::Number.negative.round(2) }
      end
    end
  end
end
