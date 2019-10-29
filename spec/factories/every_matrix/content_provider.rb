# frozen_string_literal: true

FactoryBot.define do
  factory :every_matrix_content_provider,
          class: EveryMatrix::ContentProvider.name do

    logo_url { Faker::Internet.url }
    name { Faker::Lorem.word }
    representation_name { Faker::Lorem.word }
  end
end
