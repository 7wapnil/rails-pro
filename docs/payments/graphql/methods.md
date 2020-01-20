## Payment method fields <sub><sup>(only for withdrawal payment methods)</sup></sub>

```
## PaymentMethodBitcoin

id: ID!
title: String!
isEditable: Boolean!
address: String!

## PaymentMethodCreditCard

id: ID!
title: String!
holderName: String!
lastFourDigits: String!
tokenId: String!
maskedAccountNumber: String!

## PaymentMethodNeteller

id: ID!
title: String!
name: String!
userPaymentOptionId: String!

## PaymentMethodSkrill

id: ID!
title: String!
name: String!
userPaymentOptionId: String!

## PaymentMethodEcoPayz

id: ID!
title: String!
name: String!
userPaymentOptionId: String!

## PaymentMethodIdebit

id: ID!
title: String!
name: String!
userPaymentOptionId: String!
```
