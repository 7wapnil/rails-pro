FactoryBot.define do
  factory :customer_bonus do
    customer
    wallet
    sequence(:code) { |n| "FOOBAR#{n}" }
    kind { 0 }
    rollover_multiplier { 10 }
    max_rollover_per_bet { 150.00 }
    max_deposit_match { 1000.00 }
    min_odds_per_bet { 1.6 }
    min_deposit { 10.00 }
    expires_at { Time.zone.now.end_of_month }
    valid_for_days { 60 }
    association :original_bonus, factory: :bonus
    created_at { Time.zone.now }
    deleted_at { nil }
  end

  factory :comment do
    text { 'MyText' }
    commentable_id { 1 }
    commentable_type { VerificationDocument }
    belongs_to { user }
  end
  factory :label_join do
    label { nil }
  end
  # Financials

  factory :entry_currency_rule do
    currency
    kind { EntryRequest.kinds.keys.first }
    min_amount { Faker::Number.decimal(1, 2) }
    max_amount { Faker::Number.decimal(4, 2) }
  end

  factory :currency do
    name { Faker::Currency.name }
    code { Currency.available_currency_codes.sample }
    primary { false }

    trait :primary do
      primary { true }
    end

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

    trait :with_entry do
      after(:create) do |entry_request|
        create(
          :entry_currency_rule,
          currency: entry_request.currency,
          kind: entry_request.kind,
          min_amount: 0,
          max_amount: entry_request.amount
        )
        wallet = create(
          :wallet,
          customer: entry_request.customer,
          currency: entry_request.currency
        )
        create(
          :entry,
          wallet: wallet,
          kind: entry_request.kind,
          amount: entry_request.amount
        )
      end
    end
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

  factory :betting_limit do
    customer
    title
    live_bet_delay { Faker::Number.between(1, 10) }
    user_max_bet { Faker::Number.between(1, 1000) }
    max_loss { Faker::Number.between(1, 1000) }
    max_win { Faker::Number.between(1, 1000) }
    user_stake_factor { Faker::Number.decimal(1, 1) }
    live_stake_factor { Faker::Number.decimal(1, 1) }
  end

  factory :deposit_limit do
    customer
    currency
    value { Faker::Number.decimal(3, 1) }
    range { 30 }

    trait :reached do
      after(:create) do |deposit_limit|
        create(
          :entry_request,
          :with_entry,
          customer: deposit_limit.customer,
          currency: deposit_limit.currency,
          kind: :deposit,
          amount: deposit_limit.value
        )
      end
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
    expires_at { Time.zone.now.end_of_month }
    valid_for_days { 60 }
    percentage { 100 }
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
    date_of_birth { rand(18..50).years.ago }
    gender { Customer.genders.keys.sample }
    phone { "+37258389#{rand(100..999)}" }
    sign_in_count { [*1..200].sample }
    current_sign_in_at { Faker::Time.between(1.week.ago, Time.zone.now).in_time_zone } # rubocop:disable Metrics/LineLength
    last_sign_in_at { Faker::Time.between(Date.yesterday, Time.zone.now).in_time_zone } # rubocop:disable Metrics/LineLength
    current_sign_in_ip { Faker::Internet.ip_v4_address }
    last_sign_in_ip { Faker::Internet.ip_v4_address }
    password { 'iamverysecure' }
    verified { false }
    activated { false }
    activation_token { Faker::Internet.password }
    locked { false }
    lock_reason { nil }
    locked_until { nil }

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
    sequence :external_id do |n|
      "sr:sport:#{n}"
    end
  end

  factory :event_scope do
    title
    name { 'FPSThailand CS:GO Pro League Season#4' }
    kind { :tournament }
    sequence :external_id do |n|
      "sr:tournament:#{n}"
    end
    factory :event_scope_country do
      kind { :country }
      name { Faker::Address.country }
    end
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
    sequence :external_id do |n|
      "sr:match:#{n}"
    end
    status { 0 }
    payload { {} }

    trait :upcoming do
      start_at { 1.hour.from_now }
      end_at { nil }
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

    sequence :external_id do |n|
      "sr:match:#{n}:209/setnr=2|gamenrX=#{n}|gamenrY=#{n}"
    end

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

    sequence :external_id do |n|
      "sr:match:#{n}:280/hcp=0.5:#{n}"
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
