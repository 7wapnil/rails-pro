FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password 'iamverysecure'
  end

  factory :customer do
    username { Faker::Internet.user_name }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    date_of_birth { Faker::Date.birthday }
    gender { Customer.genders.keys.sample }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.phone_number }
    sign_in_count { [*1..200].sample }
    current_sign_in_at { Faker::Time.between(1.week.ago, Date.today).in_time_zone } # rubocop:disable Metrics/LineLength
    last_sign_in_at { Faker::Time.between(Date.yesterday, Date.today).in_time_zone } # rubocop:disable Metrics/LineLength
    current_sign_in_ip { Faker::Internet.ip_v4_address }
    last_sign_in_ip { Faker::Internet.ip_v4_address }
    password 'iamverysecure'
  end

  factory :customer_note do
    customer
    user
    content { Faker::Lorem.paragraph }
  end

  factory :address do
    customer
    country { Faker::Address.country }
    state { Faker::Address.state }
    city { Faker::Address.city }
    street_address { Faker::Address.street_address }
    zip_code { Faker::Address.zip_code }
  end

  # Markets data

  factory :discipline do
    name 'CS:GO'
    kind :esports
  end

  factory :event_scope do
    discipline
    name 'FPSThailand CS:GO Pro League Season#4'
    kind :tournament
  end

  factory :scoped_event do
    event_scope
    event
  end

  factory :event do
    discipline
    name 'MiTH vs. Beyond eSports'
    description 'FPSThailand CS:GO Pro League Season#4 | MiTH vs. Beyond eSports' # rubocop:disable Metrics/LineLength
    start_at { 2.hours.ago }
    end_at { 1.hours.ago }
  end

  factory :market do
    event
    name 'Winner Map (Train)'
    priority 2
  end

  factory :odd do
    market
    name 'MiTH'
    won true
  end

  factory :odd_value do
    odd
    value 1.85
  end
end
