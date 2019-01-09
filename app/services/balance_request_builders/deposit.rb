module BalanceRequestBuilders
  class Deposit < BaseBuilder
    def initialize(entry_request, real_money:, bonus:)
      super(entry_request)
      @real_money = real_money
      @bonus = bonus
    end

    def build!
      build_cache
    end

    private

    attr_reader :real_money, :bonus

    def build_cache
      @build_cache ||= balance_entry_requests.map do |request|
        request.save!
        request
      end
    end

    def balance_entry_requests
      [bonus_balance_entry_request, real_balance_entry_request].compact
    end

    def bonus_balance_entry_request
      return if bonus.zero?

      BalanceEntryRequest.new(entry_request: entry_request,
                              amount: bonus,
                              kind: Balance::BONUS)
    end

    def real_balance_entry_request
      return if real_money.zero?

      BalanceEntryRequest.new(entry_request: entry_request,
                              amount: real_money,
                              kind: Balance::REAL_MONEY)
    end
  end
end
