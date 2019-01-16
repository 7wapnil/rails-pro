# frozen_string_literal: true

FactoryBot.define do
  factory :label_join do
    label
    association :labelable, factory: :customer
  end
end
