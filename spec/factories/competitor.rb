# frozen_string_literal: true

FactoryBot.define do
  factory :competitor do
    name { Faker::Lorem.word }
    external_id { "sr:competitor:#{Faker::Number.number(10)}" }

    trait :with_players do
      after(:create) do |competitor|
        competitor.players << create_list(:player, 2)
      end
    end
  end
end
