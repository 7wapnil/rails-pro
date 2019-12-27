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
        .joins(:entry)
        .where('every_matrix_transactions.amount > 0')
        .where('every_matrix_transactions.created_at > ?',
               HISTORY_DAYS.days.ago)
        .includes(
          :content_provider, :vendor, :currency,
          :wallet_session, :wallet, :play_item
        )
        .order(created_at: :desc)
    end
  end
end
