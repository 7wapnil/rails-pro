# frozen_string_literal: true

FactoryBot.define do
  factory :player do
    name { Faker::Lorem.word }
    full_name { Faker::Lorem.word }
    external_id { "sr:player:#{Faker::Number.number(10)}" }
  end
end
