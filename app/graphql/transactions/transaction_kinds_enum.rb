# frozen_string_literal: true

module Transactions
  TransactionKindsEnum = GraphQL::EnumType.define do
    name 'TransactionKind'

    value EntryRequest::DEPOSIT, 'deposit'
    value EntryRequest::WITHDRAW, 'withdraw'
  end
end
