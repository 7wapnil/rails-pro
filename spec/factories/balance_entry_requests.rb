FactoryBot.define do
  factory :balance_entry_request do
    kind { Balance::REAL_MONEY }
    amount { 25.0 }
    entry_request
  end
end
