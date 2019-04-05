# frozen_string_literal: true

FactoryBot.define do
  factory :competitor do
    name { Faker::Lorem.word }
    external_id { "sr:competitor:#{Faker::Number.number(10)}" }
  end
end
