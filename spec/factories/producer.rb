# frozen_string_literal: true

FactoryBot.define do
  factory :producer, class: 'Radar::Producer' do
    sequence(:id, 10) { |n| n }
    recover_requested_at { nil }
    code { Faker::Lorem.word.to_sym }
    recovery_snapshot_id { Faker::Number.number(8) }
    state { Radar::Producer::HEALTHY }
    last_successful_subscribed_at do
      Faker::Time.between(Time.zone.now - 30.second, Time.zone.now - 1.second)
    end

    factory :liveodds_producer do
      id { 1 }
      code { :liveodds }
    end

    factory :prematch_producer do
      id { 3 }
      code { :pre }
    end
  end
end
