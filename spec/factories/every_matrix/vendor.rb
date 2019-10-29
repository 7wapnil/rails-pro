# frozen_string_literal: true

FactoryBot.define do
  factory :every_matrix_vendor,
          class: EveryMatrix::Vendor.name do

    name { Faker::Lorem.word }
    sequence(:vendor_id, 10) { |n| n }
  end
end
