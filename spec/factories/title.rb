# frozen_string_literal: true

FactoryBot.define do
  factory :title do
    name        { Faker::Name.unique.name }
    kind        { :esports }
    external_id { "sr:sport:#{Faker::Number.number(10)}" }

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
