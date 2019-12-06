# frozen_string_literal: true

FactoryBot.define do
  factory :play_item_category, class: EveryMatrix::PlayItemCategory.name do
    sequence(:position) { |n| n }

    category { build(:category) }
    play_item { build(:casino_game) }
  end
end
