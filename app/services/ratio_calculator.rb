# frozen_string_literal: true

class RatioCalculator < ApplicationService
  FULL_RATIO = 1.0

  def initialize(real_money_amount:, bonus_amount:)
    @real_money_amount = real_money_amount.to_f
    @bonus_amount = bonus_amount.to_f
  end

  def call
    return FULL_RATIO if total_amount.zero?

    (real_money_amount / total_amount).round(5)
  end

  private

  attr_reader :real_money_amount, :bonus_amount

  def total_amount
    @total_amount ||= real_money_amount + bonus_amount
  end
end
