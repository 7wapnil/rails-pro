# frozen_string_literal: true

FactoryBot.define do
  factory :producer, class: Radar::Producer.name do
    sequence(:id, 10) { |n| n }
    recover_requested_at { nil }
    code { Faker::Lorem.word.to_sym }
    recovery_snapshot_id { Faker::Number.number(8) }
    state { Radar::Producer::HEALTHY }
    last_successful_subscribed_at do
      Faker::Time.between(Time.zone.now - 30.second, Time.zone.now - 1.second)
    end

    factory :liveodds_producer do
      id { Radar::Producer::LIVE_PROVIDER_ID }
      code { Radar::Producer::LIVE_PROVIDER_CODE }
    end

    factory :prematch_producer do
      id { Radar::Producer::PREMATCH_PROVIDER_ID }
      code { Radar::Producer::PREMATCH_PROVIDER_CODE }
    end

    initialize_with do
      Radar::Producer
        .find_or_initialize_by(code: code) do |producer|
        producer.assign_attributes(
          id: producer.id,
          recover_requested_at: producer.recover_requested_at,
          recovery_snapshot_id: producer.recovery_snapshot_id,
          state: producer.state,
          last_successful_subscribed_at:
            producer.last_successful_subscribed_at
        )
      end
    end
  end
end
