# frozen_string_literal: true

FactoryBot.define do
  factory :event_competitor do
    association :competitor, strategy: :build
    association :event, strategy: :build
  end
end
