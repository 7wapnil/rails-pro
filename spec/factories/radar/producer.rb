# frozen_string_literal: true

FactoryBot.define do
  factory :producer, class: Radar::Producer.name do
    sequence(:id, 10) { |n| n }
    code { Faker::Alphanumeric.alpha(10).to_sym }
    state { Radar::Producer::HEALTHY }
    last_subscribed_at { rand(1..5).seconds.ago }

    factory :liveodds_producer do
      id { Radar::Producer::LIVE_PROVIDER_ID }
      code { Radar::Producer::LIVE_PROVIDER_CODE }
    end

    factory :prematch_producer do
      id { Radar::Producer::PREMATCH_PROVIDER_ID }
      code { Radar::Producer::PREMATCH_PROVIDER_CODE }
    end

    trait :recovering do
      state { Radar::Producer::RECOVERING }
      recovery_snapshot_id { Faker::Number.number(8).to_i }
      recovery_node_id { Faker::Number.number(8).to_i }

      recovery_requested_at do
        Faker::Time.between(5.minutes.ago, 10.minutes.ago)
      end

      last_disconnected_at do
        Faker::Time.between(10.minutes.ago, 15.minutes.ago)
      end
    end

    trait :healthy do
      state { Radar::Producer::HEALTHY }
      last_disconnected_at {}
      recovery_snapshot_id {}
      recovery_node_id {}
      recovery_requested_at {}
    end

    trait :unsubscribed do
      state { Radar::Producer::UNSUBSCRIBED }
      last_disconnected_at { last_subscribed_at }
      recovery_snapshot_id {}
      recovery_node_id {}
      recovery_requested_at {}
    end

    initialize_with do
      Radar::Producer
        .find_or_initialize_by(code: code) do |producer|
        producer.assign_attributes(
          id: producer.id,
          recovery_requested_at: producer.recovery_requested_at,
          recovery_snapshot_id: producer.recovery_snapshot_id,
          state: producer.state,
          last_subscribed_at: producer.last_subscribed_at
        )
      end
    end
  end
end
