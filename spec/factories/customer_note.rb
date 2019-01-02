# frozen_string_literal: true

FactoryBot.define do
  factory :customer_note do
    content { Faker::Lorem.paragraph }

    customer
    user
  end
end
