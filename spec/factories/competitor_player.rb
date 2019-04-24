# frozen_string_literal: true

FactoryBot.define do
  factory :competitor_player do
    association :competitor, strategy: :build
    association :player, strategy: :build
  end
end
