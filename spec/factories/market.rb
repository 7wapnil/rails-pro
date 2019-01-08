# frozen_string_literal: true

FactoryBot.define do
  factory :market do
    visible  { true }
    name     { 'Winner Map (Train)' }
    priority { 2 }
    status   { Market::INACTIVE }

    sequence :external_id do |n|
      "sr:match:#{n}:209/setnr=2|gamenrX=#{n}|gamenrY=#{n}"
    end

    event

    trait :with_odds do
      after(:create) do |market|
        create_list(:odd, 2, market: market)
      end
    end

    trait :suspended do
      status { Market::SUSPENDED }
    end
  end
end
