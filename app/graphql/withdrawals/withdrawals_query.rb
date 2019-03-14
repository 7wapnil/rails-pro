module Withdrawals
  class WithdrawalsQuery < ::Base::Resolver
    include ::Base::Pagination

    type !types[WithdrawalType]

    description 'Get all withdrawals'

    def resolve(_obj, _args)
      EntryRequest
        .withdraw
        .where(customer_id: @current_customer)
        .order(created_at: :desc)
    end
  end
end
