# Payment methods

## Credit card

**Deposit:** `true`

**Withdraw:** `true`

```
{
    description: "Holder's full name",
    code: :holder_name,
    type: :string,
},
{
    description: "Masked account number (e.g. 5937 **** 9992)",
    code: :masked_account_number,
    type: :string
},
{
    description: "Token, which represents encrypted credit card data",
    code: :token_id,
    type: :string
}
```

## Neteller

**Deposit:** `true`

**Withdraw:** `true`

```
{
    description: 'Neteller option name',
    code: :name,
    type: :string
},
{
    description: 'Neteller option id',
    code: :user_payment_option_id,
    type: :string
}
```

## Skrill

**Deposit:** `true`

**Withdraw:** `true`

```
{
    description: 'Skrill option name',
    code: :name,
    type: :string
},
{
    description: 'Skrill option id',
    code: :user_payment_option_id,
    type: :string
}
```

## paysafecard

**Deposit:** `true`

**Withdraw:** `false`

## iDebit

**Deposit:** `true`

**Withdraw:** `true`

```
{
    description: 'iDebit option name',
    code: :name,
    type: :string
},
{
    description: 'iDebit option id',
    code: :user_payment_option_id,
    type: :string
}
```

## Bitcoin

**Deposit:** `true`

**Withdraw:** `true`

```
{
    description: 'Bitcoin address',
    code: :address,
    type: :string
}
```
