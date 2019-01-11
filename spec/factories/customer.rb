# frozen_string_literal: true

FactoryBot.define do
  factory :customer do
    first_name          { Faker::Name.first_name }
    last_name           { Faker::Name.last_name }
    date_of_birth       { rand(18..50).years.ago }
    gender              { Customer.genders.keys.sample }
    phone               { "+37258389#{rand(100..999)}" }
    sign_in_count       { [*1..200].sample }
    current_sign_in_at  { Faker::Time.between(1.week.ago, Time.zone.now).in_time_zone } # rubocop:disable Metrics/LineLength
    last_sign_in_at     { Faker::Time.between(Date.yesterday, Time.zone.now).in_time_zone } # rubocop:disable Metrics/LineLength
    current_sign_in_ip  { Faker::Internet.ip_v4_address }
    last_sign_in_ip     { Faker::Internet.ip_v4_address }
    password            { 'iamverysecure' }
    verified            { false }
    activated           { false }
    activation_token    { Faker::Internet.password }
    locked              { false }
    lock_reason         { nil }
    locked_until        { nil }

    sequence(:email)    { |n| "#{n}-#{Faker::Internet.email}" }
    sequence(:username) { |n| "#{Faker::Internet.user_name}#{n}" }

    trait :ready_to_bet do
      after(:create) do |customer|
        currency = create(:currency, :with_bet_rule)
        create(:wallet, customer: customer, currency: currency)
      end
    end

    factory :customer_with_betting_limits do
      after(:create) do |customer|
        create(:betting_limit, customer: customer, title: nil)
        title = create(:title)
        create(:betting_limit, customer: customer, title: title)
      end
    end
  end
end