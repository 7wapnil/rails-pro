FactoryBot.define do
  factory :entry_currency_rule do
    currency
    kind { EntryRequest.kinds.keys.first }
    min_amount { Faker::Number.decimal(3, 2) }
    max_amount { Faker::Number.decimal(3, 2) }
  end

  factory :currency do
    name { Faker::Currency.name }
    code { Faker::Currency.code }
  end

  factory :entry_request_payload do
    customer_id { create(:customer).id }
    kind { EntryRequest.kinds.keys.first }
    amount Random.new.rand(1.00..200.00).round(2)
    currency_code { create(:currency).code }
  end

  factory :entry_request do
    status EntryRequest.statuses[:pending]
    payload { attributes_for(:entry_request_payload) }
  end

  factory :balance_entry do
    entry
    balance
    amount { Faker::Number.decimal(3, 2) }
  end

  factory :entry do
    wallet
    kind 0
    amount { Faker::Number.decimal(3, 2) }
  end

  factory :balance do
    wallet
    kind 0
    amount { Faker::Number.decimal(3, 2) }
  end

  factory :wallet do
    customer
    currency
    amount { Faker::Number.decimal(3, 2) }
  end

  factory :label do
    name 'MyString'
    description 'MyText'
  end

  factory :user do
    email { Faker::Internet.email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password 'iamverysecure'

    factory :admin_user do
      email 'admin@email.com'
      first_name 'Super'
      last_name 'Admin'
      password 'iamadminuser'
    end
  end

  factory :customer do
    username do
      loop do
        username = Faker::Internet.user_name
        break username unless Customer.exists?(username: username)
      end
    end

    email do
      loop do
        email = Faker::Internet.email
        break email unless Customer.exists?(email: email)
      end
    end

    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    date_of_birth { Faker::Date.birthday }
    gender { Customer.genders.keys.sample }
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

  factory :title do
    name 'CS:GO'
    kind :esports
  end

  factory :event_scope do
    title
    name 'FPSThailand CS:GO Pro League Season#4'
    kind :tournament
  end

  factory :scoped_event do
    event_scope
    event
  end

  factory :event do
    title
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
