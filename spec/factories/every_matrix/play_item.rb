# frozen_string_literal: true

FactoryBot.define do
  factory :play_item, class: EveryMatrix::Table.name do
    factory :casino_game, class: EveryMatrix::Game.name
    factory :casino_table, class: EveryMatrix::Table.name

    sequence(:external_id, 10, &:to_s)
    url { Faker::Internet.url }
    name { Faker::Lorem.word }
    slug { Faker::Internet.slug }
    association :vendor, factory: :every_matrix_vendor
    content_provider { create(:every_matrix_content_provider) }

    trait :unique_names do
      name { Faker::Name.unique.name }
    end

    desktop
    trait :desktop do
      terminal { EveryMatrix::PlayItem::DESKTOP_PLATFORM }
    end

    trait :mobile do
      terminal { EveryMatrix::PlayItem::MOBILE_PLATFORMS }
    end

    trait :with_recommended_games do
      after(:create) do |play_item|
        play_item.update(
          last_updated_recommended_games_at: Time.zone.now,
          recommended_games: create_list(:casino_game, 5)
        )
      end
    end
  end
end
