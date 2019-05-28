module BalanceRequestBuilders
  class WinPayout < BaseBuilder
    protected

    def balance_entry_requests
      [bonus_balance_entry_request, real_balance_entry_request].compact
    end

    def bonus_balance_entry_request
      return nil unless customer_bonus&.active?

      super
    end

    def customer_bonus
      entry_request.origin.customer_bonus
    end
  end
end
