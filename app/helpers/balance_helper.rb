# frozen_string_literal: true

module BalanceHelper
  def wallet_balances_for(customer)
    customer.wallets.map { |wallet| wallet_balance(wallet) }.join(' / ')
  end

  def wallet_balance(wallet)
    "#{wallet.amount} #{wallet.currency_code}"
  end

  def displayed_amount(object)
    return '-' unless object
    return 0.0 if object.amount.zero?

    format('%+g', object.amount)
  end
end
