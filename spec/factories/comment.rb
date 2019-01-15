# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    association :commentable, factory: :verification_document
    user

    text { Faker::Lorem.sentence }
  end
end
