# frozen_string_literal: true

FactoryBot.define do
  factory :address do
    country        { Faker::Address.country }
    state          { Faker::Address.state }
    city           { Faker::Address.city }
    street_address { Faker::Address.street_address }
    zip_code       { Faker::Address.zip_code }

    customer
  end
end
