# frozen_string_literal: true

FactoryBot.define do
  factory :title do
    name                   { Faker::Name.unique.name }
    kind                   { :esports }

    sequence(:external_id) { |n| "sr:sport:#{n}" }
  end
end
