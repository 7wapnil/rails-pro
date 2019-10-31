# frozen_string_literal: true

FactoryBot.define do
  factory :casino_game, class: EveryMatrix::Game.name do
    sequence(:external_id, 10, &:to_s)
    url { Faker::Internet.url }
    name { Faker::Lorem.word }

    vendor { create(:every_matrix_vendor) }
    content_provider { create(:every_matrix_content_provider) }
  end
end
