module BalanceRequestBuilders
  class BaseBuilder < ApplicationService
    def initialize(entry_request, real_money: 0, bonus: 0)
      @entry_request = entry_request
      @real_money = real_money
      @bonus = bonus
    end

    def call
      build!
    end

    def build!
      build_cache
    end

    protected

    attr_accessor :entry_request, :real_money, :bonus

    def build_cache
      @build_cache ||= balance_entry_requests.map do |request|
        request.save!
        request
      end
    end

    def balance_entry_requests
      error_msg = "#{__method__} needs to be implemented in #{self.class}"
      raise NotImplementedError, error_msg
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
