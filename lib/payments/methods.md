# Payment methods

## Credit card

**Deposit:** `true`

**Withdraw:** `true`

```
{
    name: "Holder's full name",
    code: :holder_name,
    type: :string
},
{
    name: "Card's last four digits",
    code: :last_four_digits,
    type: :string
}
```

## Neteller

**Deposit:** `true`

**Withdraw:** `true`

```
{
    name: 'Neteller account id',
    code: :account_id,
    type: :string
},
{
    name: 'Secure ID',
    code: :secure_id,
    type: :string
}
```

## Skrill

**Deposit:** `true`

**Withdraw:** `true`

```
{
    name: 'Skrill email address',
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
    name: 'Bitcoin address',
    code: :address,
    type: :string
}
```
