# frozen_string_literal: true

FactoryBot.define do
  factory :market_template do
    external_id { Faker::Number.between(1, 1000) }
    name        { Faker::Name.unique.name }
    groups      { 'all' }
    payload     { { test: 1 } }
    category    { MarketTemplate::POPULAR }

    transient do
      specific_outcome_id { '4' }
      specific_outcome_name { 'zoo' }
    end

    trait :products_live do
      payload { { products: %w[1] } }
    end

    trait :products_prelive do
      payload { { products: %w[3] } }
    end

    trait :products_all do
      payload { { products: %w[1 3] } }
    end

    trait :with_outcome_data do
      payload do
        {
          outcomes: {
            outcome: [
              { 'id' => '1', 'name' => 'foo' },
              { 'id' => '2', 'name' => 'bar' },
              { 'id' => '3', 'name' => 'baz' },
              { 'id' => specific_outcome_id,
                'name' => specific_outcome_name }
            ]
          }
        }
      end
    end
  end
end
