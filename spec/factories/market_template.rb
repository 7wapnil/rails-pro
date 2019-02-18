# frozen_string_literal: true

FactoryBot.define do
  factory :market_template do
    external_id { Faker::Number.between(1, 1000) }
    name        { Faker::Name.unique.name }
    groups      { 'all' }
    payload     { { test: 1 } }
    category    { MarketTemplate::POPULAR }

    trait :products_live do
      payload { { products: %w[1] } }
    end

    trait :products_prelive do
      payload { { products: %w[3] } }
    end

    trait :products_all do
      payload { { products: %w[1 3] } }
    end
  end
end
