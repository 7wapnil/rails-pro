module Withdrawals
  class WithdrawalsQuery < ::Base::Resolver
    type !types[WithdrawalType]

    description 'Get all withdrawals'

    argument :customerId, types.ID
    argument :page, types.Int
    argument :perPage, types.Int

    def resolve(_obj, args)
      WithdrawalsQueryResolver.new(args).resolve
    end
  end
end
