# frozen_string_literal: true

module EveryMatrix
  class TransactionsQuery < ::Base::Resolver
    include ::Base::Pagination

    description 'Get Every Matrix transactions'

    type !types[EveryMatrixTransactionType]

    def resolve(_obj, _args)
      customer_transactions
    end

    private

    def customer_transactions
      EveryMatrix::Transaction
        .where(customer: current_customer)
        .includes(em_wallet_session: { wallet: :currency })
        .order(created_at: :desc)
    end
  end
end
