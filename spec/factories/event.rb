# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    visible                { true }
    active                 { true }
    name                   { 'MiTH vs. Beyond eSports' }
    description            { 'FPSThailand CS:GO Pro League Season#4 | MiTH vs. Beyond eSports' } # rubocop:disable Metrics/LineLength
    start_at               { 2.hours.ago }
    end_at                 { 1.hours.ago }
    remote_updated_at      { Time.zone.now }
    status                 { Event::NOT_STARTED }
    payload                { {} }

    sequence(:external_id) { |n| "sr:match:#{n}" }

    association :title, strategy: :build
    producer

    trait :upcoming do
      start_at { 1.hour.from_now }
      end_at   { nil }
    end

    trait :live do
      end_at      {}
      traded_live { true }
    end

    trait :bookable do
      payload { { 'liveodds': 'bookable' } }
    end

    trait :inactive do
      active { false }
    end

    trait :invisible do
      visible { false }
    end

    factory :event_with_market do
      after(:create) do |event|
        create(:market, event: event)
      end
    end

    factory :event_with_odds do
      after(:create) do |event|
        create_list(:odd, 2, market: create(:market, event: event))
      end
    end
  end
end
