# frozen_string_literal: true

FactoryBot.define do
  factory :affiliate do
    name { Faker::Internet.domain_word }
    b_tag { Faker::IDNumber.valid }
    sports_revenue_share { [*0..50].sample }
    casino_revenue_share { [*0..50].sample }
    cost_per_acquisition { [*0..100].sample }
  end
end
