# frozen_string_literal: true

module EveryMatrix
  EveryMatrixTransactionType = GraphQL::ObjectType.define do
    name 'EveryMatrixTransactions'

    field :id, !types.ID
    field :customerId, types.ID, property: :customer_id
    field :debit, types.Float, resolve: ->(obj, _args, _ctx) do
      obj.amount if EveryMatrix::Transaction::DEBIT_TYPES.include?(obj.type)
    end
    field :credit, types.Float, resolve: ->(obj, _args, _ctx) do
      obj.amount if EveryMatrix::Transaction::CREDIT_TYPES.include?(obj.type)
    end
    field :balance, types.Float,
          resolve: ->(obj, _args, _ctx) { obj.entry.balance_amount_after }
    field :currencyCode, !types.String,
          resolve: ->(obj, _args, _ctx) { obj.currency.code }
    field :type, !types.String,
          resolve: ->(obj, _args, _ctx) { obj.type.demodulize }
    field :transactionId, !types.ID, property: :transaction_id
    field :gameName, !types.String,
          resolve: ->(_obj, _args, _ctx) { 'Game name placeholder' }
    field :vendorName, !types.String,
          resolve: ->(_obj, _args, _ctx) { 'Vendor name placeholder' }
    field :createdAt, types.String, resolve: ->(obj, _args, _ctx) do
      obj.created_at.strftime('%e.%m.%y %H:%M:%S')
    end
  end
end
