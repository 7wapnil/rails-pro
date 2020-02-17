# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    visible                { true }
    active                 { true }
    ready                  { true }
    name                   { "#{Faker::Esport.team} vs. #{Faker::Esport.team}" }
    meta_description       { 'FPSThailand CS:GO Pro League Season#4 | MiTH vs. Beyond eSports' } # rubocop:disable Metrics/LineLength
    start_at               { 2.hours.ago }
    end_at                 { 1.hours.ago }
    remote_updated_at      { Time.zone.now }
    status                 { Event::NOT_STARTED }

    external_id { "sr:match:#{Faker::Number.number(10)}" }

    association :title, strategy: :build
    association :producer, factory: :prematch_producer

    trait :with_event_scopes do
      after :build do |model|
        model.title = FactoryBot.random_or_create :title
        model.event_scopes << FactoryBot.random_or_create(:event_scope)
      end
    end

    trait :upcoming do
      start_at { 1.hour.from_now }
      end_at   { nil }
    end

    trait :live do
      status { Event::IN_PLAY_STATUSES.sample }
      traded_live { true }
    end

    trait :bookable do
      liveodds { 'bookable' }
    end

    trait :inactive do
      active { false }
    end

    trait :invisible do
      visible { false }
    end

    trait :with_market do
      after(:create) do |event|
        create(:market, event: event, status: Market::ACTIVE)
      end
    end

    trait :with_odds do
      after(:create) do |event|
        create_list(:odd, 2, :active, market: create(:market,
                                                     event: event,
                                                     status: Market::ACTIVE))
      end
    end
  end
end
