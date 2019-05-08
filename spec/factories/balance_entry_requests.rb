FactoryBot.define do
  factory :balance_entry_request do
    kind { Balance::REAL_MONEY }
    amount { Faker::Number.decimal(2, 2).to_d }
    entry_request
  end
end
