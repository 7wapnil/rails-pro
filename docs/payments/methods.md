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
    description: 'Neteller account id',
    code: :account_id,
    type: :string
}
```

## Skrill

**Deposit:** `true`

**Withdraw:** `true`

```
{
    description: 'Skrill email address',
    code: :email,
    type: :string
}
```

## Paysafecard

**Deposit:** `true`

**Withdraw:** `false`

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
