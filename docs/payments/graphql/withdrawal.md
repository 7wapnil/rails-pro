## Withdrawal

There are described payment methods fields that must be sent via withdraw form.

There is API mutation endpoint named `withdraw`, which accepts following fields:
```
withdraw(input: WithdrawInput): Boolean!

# WithdrawInput

password: String!
amount: Float!
currencyCode: String!
paymentMethod: WithdrawalsPaymentMethodEnum!
paymentDetails: [PaymentMethodDetail!]!
```

Types definition:

```
# WithdrawalsPaymentMethodEnum

- credit_card, 'MasterCard/Visa'
- neteller, 'Neteller'
- skrill, 'Skrill'
- bitcoin, 'Bitcoin'
- idebit, 'iDebit'

# PaymentMethodDetail

code: String!
value: String!
```

`paymentDetails` is demonstrated in [a list of payment details fields](https://github.com/arcanebet/backend/blob/master/docs/payments/methods.md).

## Available withdrawal methods

Available withdrawal methods can be received on front-end from `user` API query.
```
user {
  availablePaymentMethods: [WithdrawalsPaymentMethod!]
}: User

# WithdrawalsPaymentMethod

id: ID!
name: String!
note: String
description: String
code: String!
details: PaymentsWithdrawalsPaymentMethodDetails
currencyCode: String
```

Types definition:

##### `PaymentsWithdrawalsPaymentMethodDetails`

This is GraphQL union type. It requires definition of queried fields for [every listed payment method type](https://github.com/arcanebet/backend/blob/master/docs/payments/graphql/methods.md).
