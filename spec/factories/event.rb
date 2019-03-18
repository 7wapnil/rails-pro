# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    visible                { true }
    active                 { true }
    description            { 'FPSThailand CS:GO Pro League Season#4 | MiTH vs. Beyond eSports' } # rubocop:disable Metrics/LineLength
    start_at               { 2.hours.ago }
    end_at                 { 1.hours.ago }
    remote_updated_at      { Time.zone.now }
    status                 { Event::NOT_STARTED }
    payload                { {} }

    sequence(:external_id) { |n| "sr:match:#{n}" }

    association :title, strategy: :random_or_create

    name do
      faker = if title.kind == Title::ESPORTS
                Faker::Esport
              else
                Faker::Football
              end
      "#{faker.team} vs. #{faker.team}"
    end

    association :producer, factory: :prematch_producer

    after :create do |model|
      model.event_scopes << FactoryBot.random_or_create(:event_scope)
      model.add_to_payload(
        state:
          OddsFeed::Radar::EventStatusService.new.call(
            event_id: Faker::Number.number(3), data: nil
          )
      )
      model.save!
    end

    trait :upcoming do
      start_at { 1.hour.from_now }
      end_at   { nil }
    end

    trait :live do
      end_at      { nil }
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

    trait :with_market do
      after(:create) do |event|
        create(:market, event: event)
      end
    end

    trait :with_odds do
      after(:create) do |event|
        create_list(:odd, 2, :active, market: create(:market, event: event))
      end
    end
  end
end
