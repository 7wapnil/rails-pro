# frozen_string_literal: true

FactoryBot.define do
  factory :every_matrix_vendor,
          class: EveryMatrix::Vendor.name do

    name { Faker::Lorem.word }
    slug { Faker::Internet.slug }
    sequence(:vendor_id, 10) { |n| n }
    external_status { EveryMatrix::Vendor::ACTIVATED }

    trait :deactivated do
      external_status { EveryMatrix::Vendor::DEACTIVATED }
    end

    trait :visible do
      visible { true }
    end
  end
end
