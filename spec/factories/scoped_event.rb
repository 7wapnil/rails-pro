# frozen_string_literal: true

FactoryBot.define do
  factory :scoped_event do
    association :event,       strategy: :build
    association :event_scope, strategy: :build
  end
end
