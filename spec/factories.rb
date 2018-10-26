FactoryBot.define do
  # Financials

  factory :entry_currency_rule do
    currency
    kind { EntryRequest.kinds.keys.first }
    min_amount { Faker::Number.decimal(1, 2) }
    max_amount { Faker::Number.decimal(4, 2) }
  end

  factory :currency do
    name { Faker::Currency.name }
    code { Faker::Currency.code }

    trait :with_bet_rule do
      after(:create) do |currency|
        bet_kind = EntryRequest.kinds[:bet]
        create(:entry_currency_rule, currency: currency, kind: bet_kind)
      end
    end
  end

  factory :entry_request do
    customer
    currency
    status { EntryRequest.statuses[:pending] }
    mode { EntryRequest.modes[:cashier] }
    kind { EntryRequest.kinds.keys.first }
    amount { Random.new.rand(1.00..200.00).round(2) }
    comment { Faker::Lorem.paragraph }
    association :initiator, factory: :customer
  end

  factory :balance_entry do
    entry
    balance
    amount { Faker::Number.decimal(3, 2) }
  end

  factory :entry do
    wallet
    kind { EntryRequest.kinds.keys.first }
    amount { Faker::Number.decimal(3, 2) }
    authorized_at { nil }
  end

  factory :balance do
    wallet
    kind { Balance.kinds[:real_money] }
    amount { Faker::Number.decimal(3, 2) }
  end

  factory :wallet do
    customer
    currency
    amount { Faker::Number.decimal(3, 2) }

    trait :brick do
      amount { 100_000 }
    end
  end

  factory :bet do
    association :customer, :ready_to_bet
    odd
    currency
    amount { Faker::Number.decimal(2, 2) }
    odd_value { odd.value }
    status { Bet.statuses[:initial] }

    trait :settled do
      status { Bet.statuses[:settled] }
    end

    trait :accepted do
      status { Bet.statuses[:accepted] }
    end

    trait :sent_to_external_validation do
      status { Bet.statuses[:sent_to_external_validation] }

      after(:create) do |bet|
        bet_kind = EntryRequest.kinds[:bet]
        wallet = bet.customer.wallets.take
        create(:entry, kind: bet_kind, origin: bet, wallet: wallet)
      end
    end

    trait :won do
      settlement_status { :won }
    end

    trait :lost do
      settlement_status { :lost }
    end
  end

  # System

  factory :bonus do
    sequence(:code) { |n| "FOOBAR#{n}" }
    kind { 0 }
    rollover_multiplier { 10 }
    max_rollover_per_bet { 150.00 }
    max_deposit_match { 1000.00 }
    min_odds_per_bet { 1.6 }
    min_deposit { 10.00 }
    expires_at { Date.today.end_of_month }
    valid_for_days { 60 }
  end

  factory :user do
    email { Faker::Internet.email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password { 'iamverysecure' }

    factory :admin_user do
      email { 'admin@email.com' }
      first_name { 'Super' }
      last_name { 'Admin' }
      password { 'iamadminuser' }
    end
  end

  # Customers

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
    password { 'iamverysecure' }
    verified { false }
    activated { false }
    activation_token { Faker::Internet.password }

    trait :ready_to_bet do
      after(:create) do |customer|
        currency = create(:currency, :with_bet_rule)
        create(:wallet, customer: customer, currency: currency)
      end
    end
  end

  factory :label do
    sequence :name do |n|
      "My label #{n}"
    end
    sequence :description do |n|
      text = Faker::Community.quotes
      "#{text} #{n}"
    end
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

  factory :market_template do
    external_id { Faker::Number.between(1, 1000) }
    name { Faker::Name.unique.name }
    groups { 'all' }
    payload { { test: 1 } }
  end

  factory :title do
    name { Faker::Name.unique.name }
    kind { :esports }
  end

  factory :event_scope do
    title
    name { 'FPSThailand CS:GO Pro League Season#4' }
    kind { :tournament }
  end

  factory :scoped_event do
    event_scope
    event
  end

  factory :event do
    title
    visible { true }
    name { 'MiTH vs. Beyond eSports' }
    description { 'FPSThailand CS:GO Pro League Season#4 | MiTH vs. Beyond eSports' } # rubocop:disable Metrics/LineLength
    start_at { 2.hours.ago }
    end_at { 1.hours.ago }
    remote_updated_at { Time.zone.now }
    external_id { '' }
    status { 0 }
    payload { {} }
    traded_live false

    trait :upcoming do
      start_at { 1.hour.from_now }
      end_at { nil }
    end

    trait :live do
      traded_live true
    end

    factory :event_with_market do
      after(:create) do |event|
        create(:market, event: event)
      end
    end

    factory :event_with_odds do
      after(:create) do |event|
        create_list(:odd, 2, market: create(:market, event: event))
      end
    end
  end

  factory :market do
    event
    visible { true }
    name { 'Winner Map (Train)' }
    priority { 2 }
    status { 0 }

    trait :with_odds do
      after(:create) do |market|
        create_list(:odd, 2, market: market)
      end
    end
  end

  factory :odd do
    market
    name { 'MiTH' }
    won { true }
    value { Faker::Number.decimal(1, 2) }
    status { 0 }
  end

  factory(:alive_message, class: Radar::AliveMessage) do
    product_id { 1 }
    reported_at { Time.now.to_i }
    subscribed { true }

    initialize_with do
      new(
        product_id: product_id,
        reported_at: reported_at,
        subscribed: subscribed
      )
    end
  end

  factory :verification_document do
    customer
    kind { 0 }
    status { 0 }

    after(:build) do |doc|
      file_path = Rails.root.join('spec',
                                  'support',
                                  'fixtures',
                                  'files',
                                  'verification_document_image.jpg')
      doc.document.attach(io: File.open(file_path),
                          filename: 'verification_document_image.jpg',
                          content_type: 'image/jpeg')
    end
  end
end
