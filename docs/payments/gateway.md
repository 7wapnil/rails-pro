## Payments gateway

Architecture for payments gateway. 

## Usage examples:

#### FIAT

- Deposit

```ruby
# Generate payment page url
transaction = Payments::Transactions::Deposit.new(
  method: Payments::Methods::CREDIT_CARD,
  customer: customer,
  amount: 1000,
  currency_code: 'EUR',
  bonus_code: 'TEST_BONUS_CODE'
)
payment_page_url = Payments::Deposit.call(transaction)

# Handle payment callback
Payments::Fiat::Wirecard::Deposits::CallbackHandler.call(request)
```

- Withdrawal

```ruby
# Take money from balance and create pending withdrawal request
details = {
  holder_name: 'Cool guy',
  masked_account_number: '8800 **** 3535',
  token_id: 'encrypted-credit-card-token'
}
transaction = Payments::Transactions::Withdrawal.new(
  method: Payments::Methods::CREDIT_CARD,
  password: 'customer-password',
  customer: customer,
  amount: 1000,
  currency_code: 'EUR',
  details: details
)
Payments::Withdrawal.call(transaction)
```

- Payout

```ruby
# Send withdrawal request to external API
withdrawal = entry_request.origin
transaction = Payments::Transactions::Payout.new(
  id: entry_request.id,
  method: entry_request.mode,
  customer: entry_request.customer,
  currency_code: entry_request.currency.code,
  amount: entry_request.amount,
  withdrawal: withdrawal,
  details: withdrawal.details
)
Payments::Payout.call(transaction)

# Handle payment callback
Payments::Fiat::Wirecard::CallbackHandler.call(request)
```

#### Crypto

- Deposit

```ruby
# Generate payment crypto address and create pending customer bonus
transaction = Payments::Transactions::Deposit.new(
  method: Payments::Methods::BITCOIN,
  customer: customer,
  amount: 1000,
  currency_code: 'mTBTC',
  bonus_code: 'TEST_BONUS_CODE'
)
crypto_address = Payments::Deposit.call(transaction)

# Handle payment callback
Payments::Crypto::CoinsPaid::CallbackHandler.call(request)
```

- Withdrawal

```ruby
# Take money from balance and create pending withdrawal request
details = { address: 'tb1880055535353221488228322228' }
transaction = Payments::Transactions::Withdrawal.new(
  method: Payments::Methods::BITCOIN,
  password: 'customer-password',
  customer: customer,
  amount: 1000,
  currency_code: 'mTBTC',
  details: details
)
Payments::Withdrawal.call(transaction)
```

- Payout

```ruby
# Send withdrawal request to external API
withdrawal = entry_request.origin
transaction = Payments::Transactions::Payout.new(
  id: entry_request.id,
  method: entry_request.mode,
  customer: entry_request.customer,
  currency_code: entry_request.currency.code,
  amount: entry_request.amount,
  withdrawal: withdrawal,
  details: withdrawal.details
)
Payments::Payout.call(transaction)

# Handling payment callback
Payments::Crypto::CoinsPaid::CallbackHandler.call(request)
```
