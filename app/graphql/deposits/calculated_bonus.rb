# frozen_string_literal: true

module Deposits
  class CalculatedBonus
    attr_reader :real_money, :bonus

    def initialize(args)
      @real_money = args[:real_money_amount]
      @bonus = args[:bonus_amount]
    end
  end
end
