# frozen_string_literal: true

FactoryBot.define do
  factory :event_scope do
    name                   { Faker::Esport.league }
    kind                   { EventScope::TOURNAMENT }

    sequence(:external_id) { |n| "sr:tournament:#{n}" }

    trait :with_event do
      build( :build do |event_scope|
        create(:event, event_scopes: [event_scope])
      end
    end
    title

    trait :tournament do
      kind { EventScope::TOURNAMENT }
    end

    trait :category do
      kind { EventScope::CATEGORY }
      name { Faker::Address.country }
    end
  end
end
