# frozen_string_literal: true

FactoryBot.define do
  factory :game_round, class: EveryMatrix::GameRound.name do
    external_id { Faker::Alphanumeric.alphanumeric }
    status { EveryMatrix::GameRound::PENDING }
  end
end
