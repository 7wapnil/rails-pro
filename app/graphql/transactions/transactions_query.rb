module Transactions
  class TransactionsQuery < ::Base::Resolver
    include ::Base::Pagination

    type !types[TransactionType]

    description 'Get all transactions'

    argument :filter, types.String

    def resolve(_obj, args)
      TransactionsResolver.call(filter: args['filter'],
                                current_customer: @current_customer)
    end
  end
end
