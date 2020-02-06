# frozen_string_literal: true

FactoryBot.define do
  factory :every_matrix_content_provider,
          class: EveryMatrix::ContentProvider.name do

    logo_url { Faker::Internet.url }
    name { Faker::Lorem.word }
    representation_name { Faker::Lorem.word }
    slug { Faker::Internet.slug }
    external_status { EveryMatrix::ContentProvider::ACTIVATED }

    trait :deactivated do
      external_status { EveryMatrix::ContentProvider::DEACTIVATED }
    end

    trait :visible do
      visible { true }
    end

    trait :as_vendor do
      as_vendor { true }
    end
  end
end
