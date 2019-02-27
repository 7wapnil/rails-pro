module BalanceRequestBuilders
  class Withdrawal < BaseBuilder
    protected

    def balance_entry_requests
      [real_balance_entry_request].compact
    end
  end
end
