## Deposit

There are described payment methods fields that must be sent via deposit form.

There is API mutation endpoint named `deposit`, which accepts following fields:
```
deposit(input: DepositInput): DepositType!

# DepositInput

paymentMethod: DepositsPaymentMethodEnum!
currencyCode: String!
amount: Float!
bonusCode: String
    
# DepositType

url: String!
message: String!
```

Types definition:
```
# DepositsPaymentMethodEnum

- credit_card, 'MasterCard/Visa'
- neteller, 'Neteller'
- skrill, 'Skrill'
- paysafecard, 'Paysafecard'
- bitcoin, 'Bitcoin'
```

## Deposit payment methods

All deposit payment methods can be received on front-end from `depositMethods` API query.
```
depositMethods: [DepositsPaymentMethod!]!

# DepositsPaymentMethod

name: String!
note: String
code: String!
currencyCode: String
```
