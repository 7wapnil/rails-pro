# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email      { Faker::Internet.email }
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    password   { 'iamverysecure' }
    time_zone  { 'UTC' }

    factory :admin_user do
      email      { Faker::Internet.email }
      first_name { 'Super' }
      last_name  { 'Admin' }
      password   { 'iamadminuser' }
    end
  end
end
