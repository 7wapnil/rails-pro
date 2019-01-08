# frozen_string_literal: true

FactoryBot.define do
  factory :audit_log do
    event       { :customer_verified }
    customer_id { Faker::Number.between(1, 100) }
    user_id     { Faker::Number.between(1, 100) }
    created_at  { Time.zone.now }

    # rubocop:disable RSpec/EmptyExampleGroup,RSpec/MissingExampleGroupArgument
    context     { { content: Faker::Internet.email } }
    # rubocop:enable RSpec/EmptyExampleGroup,RSpec/MissingExampleGroupArgument
  end
end
