# frozen_string_literal: true

FactoryBot.define do
  factory :market_template do
    external_id { Faker::Number.between(1, 1000) }
    name        { Faker::Name.unique.name }
    groups      { 'all' }
    payload     { { test: 1 } }
    category    { MarketTemplate::POPULAR }
  end
end
