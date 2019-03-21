module Transactions
  class TransactionsQuery < ::Base::Resolver
    include ::Base::Pagination

    type !types[TransactionType]

    description 'Get all transactions'

    argument :filter, TransactionKindsEnum

    def resolve(_obj, args)
      return customer_transactions unless args['filter']

      customer_transactions.where(kind: args['filter'])
    end

    private

    def customer_transactions
      EntryRequest.transactions.where(customer_id: current_customer)
    end
  end
end
