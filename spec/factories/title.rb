# frozen_string_literal: true

FactoryBot.define do
  factory :title do
    name                   { Faker::Name.unique.name }
    kind                   { :esports }

    sequence(:external_id) { |n| "sr:sport:#{n}" }

    trait :with_event do
      after(:create) do |title|
        create(:event, :upcoming, title: title)
      end
    end

    trait :with_tournament do
      after(:create) do |title|
        create(:event_scope, title: title)
      end
    end
  end
end
