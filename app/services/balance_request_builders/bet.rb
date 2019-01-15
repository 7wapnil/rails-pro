module BalanceRequestBuilders
  class Bet < BaseBuilder
    protected

    def balance_entry_requests
      [bonus_balance_entry_request, real_balance_entry_request].compact
    end
  end
end