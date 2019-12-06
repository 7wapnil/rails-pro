# frozen_string_literal: true

FactoryBot.define do
  factory :category, class: EveryMatrix::Category.name do
    add_attribute(:context) { Faker::Lorem.word }

    kind { EveryMatrix::Category::CASINO_TYPE }

    trait :with_play_items do
      after(:create) do |category|
        category.play_items << create_list(:casino_game, 2)
      end
    end
  end
end
