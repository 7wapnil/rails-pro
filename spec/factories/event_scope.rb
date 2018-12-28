# frozen_string_literal: true

FactoryBot.define do
  factory :event_scope do
    name                   { 'FPSThailand CS:GO Pro League Season#4' }
    kind                   { EventScope::TOURNAMENT }

    sequence(:external_id) { |n| "sr:tournament:#{n}" }

    title

    factory :event_scope_country do
      kind { EventScope::COUNTRY }
      name { Faker::Address.country }
    end
  end
end
