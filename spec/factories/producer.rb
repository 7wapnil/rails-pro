# frozen_string_literal: true

FactoryBot.define do
  factory :producer, class: 'Radar::Producer' do
    id { Faker::Number.number(3) }
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

    initialize_with do
      Radar::Producer.find_or_initialize_by(id: id, code: code)
    end
  end
end
