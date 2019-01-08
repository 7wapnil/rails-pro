# frozen_string_literal: true

FactoryBot.define do
  factory :producer, class: 'Radar::Producer' do
    sequence(:id, 10) { |n| n }
    recover_requested_at { nil }
    code { Faker::Lorem.word.to_sym }

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
