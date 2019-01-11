# frozen_string_literal: true

FactoryBot.define do
  factory :event_scope do
    name                   { 'FPSThailand CS:GO Pro League Season#4' }
    kind                   { EventScope::TOURNAMENT }

    sequence(:external_id) { |n| "sr:tournament:#{n}" }

    title

    trait :with_event do
      after(:create) do |event_scope|
        create(:event, event_scopes: [event_scope])
      end
    end

    factory :event_scope_country do
      kind { EventScope::COUNTRY }
      name { Faker::Address.country }
    end
  end
end