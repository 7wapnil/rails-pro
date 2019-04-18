# frozen_string_literal: true

FactoryBot.define do
  factory :mts_connection do
    status { MtsConnection::HEALTHY }
  end
end
