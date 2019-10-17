# frozen_string_literal: true

module EveryMatrix
  class TransactionsQuery < ::Base::Resolver
    HISTORY_DAYS = 30

    include ::Base::Pagination

    description 'Get Every Matrix transactions'

    type !types[EveryMatrixTransactionType]

    def resolve(_obj, _args)
      customer_transactions
    end

    private

    def customer_transactions
      current_customer
        .every_matrix_transactions
        .where('created_at > ?', HISTORY_DAYS.days.ago)
        .includes(em_wallet_session: { wallet: :currency })
        .order(created_at: :desc)
    end
  end
end
