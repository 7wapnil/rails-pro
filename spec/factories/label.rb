# frozen_string_literal: true

FactoryBot.define do
  factory :label do
    sequence(:name)        { |n| "My label #{n}" }
    sequence(:description) { |n| "#{Faker::Community.quotes} #{n}" }
  end
end
