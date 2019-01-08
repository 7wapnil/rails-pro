# frozen_string_literal: true

FactoryBot.define do
  factory :scoped_event do
    event_scope
    event
  end
end
