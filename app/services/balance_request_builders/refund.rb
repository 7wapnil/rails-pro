module BalanceRequestBuilders
  class Refund < BaseBuilder
    protected

    def balance_entry_requests
      [bonus_balance_entry_request, real_balance_entry_request].compact
    end
  end
end