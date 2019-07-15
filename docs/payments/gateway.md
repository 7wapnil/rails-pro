## Payments gateway
Initial architecture for gateway. Usage example:

```ruby
# Generating payment page url
transaction = Payments::Transactions::Deposit.new(
  method: :credit_card,
  customer: customer,
  amount: 1000,
  currency_code: currency_code,
  bonus_code: 'TEST_BONUS_CODE'
)

Payments::Deposit.call(transaction)


# Handling response on return
Payments::Wirecard.new.handle_deposit_response(params) 

```

Schema
![gateway arch](./payments_gateway_arch.jpg "Payments gateway arch")
