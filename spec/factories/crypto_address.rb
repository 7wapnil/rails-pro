# frozen_string_literal: true

FactoryBot.define do
  factory :crypto_address do
    address { Faker::Bitcoin.address }
    wallet
  end
end
