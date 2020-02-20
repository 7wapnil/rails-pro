# frozen_string_literal: true

class MonthlyBalanceQueryResultDecorator < ApplicationDecorator
  def created_at
    I18n.l(super)
  end

  def real_money_balance_eur
    super.round(2)
  end

  def bonus_amount_balance_eur
    super.round(2)
  end

  def total_balance_eur
    super.round(2)
  end
end
