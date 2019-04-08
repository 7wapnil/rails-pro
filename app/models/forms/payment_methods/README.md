## Payment methods validation models
Here described payment methods fields that must be sent via withdraw form.
The field name is `highlighted` and similar to property that should be received from FE. 

In API mutation endpoint named `withdraw` and accepts following fields:
```
withdraw(input: WithdrawInput): Boolean!

# WithdrawInput
password: String!
amount: Float!
walletId: ID!
paymentMethod: String!
paymentDetails: [PaymentMethodDetail!]!

# PaymentMethodDetail
code: String!
value: String!
```

Depends on `paymentMethods` there is a list of payment detail fields to validate:

### Credit card
* `holder_name` - The name of card holder
* `last_four_digits` - Last 4 digits of card number
