## Payments gateway
Initial architecture for gateway. Usage example:

```ruby
transaction = Payments::Transaction.build(:credit_card)
transaction.customer = customer
transaction.amount = 1000
transaction.currency = currency
transaction.bonus_code = 'TEST_BONUS'

payments_service = Payments::Service.new
payments_service.deposit(transaction)

```

Schema
![gateway arch](./payments_gateway_arch.jpg "Payments gateway arch")
