# frozen_string_literal: true

module BalanceHelper
  def wallet_balances_for(customer)
    customer.wallets.map { |wallet| wallet_balance(wallet) }.join(' / ')
  end

  def wallet_balance(wallet, amount = nil)
    "#{amount || wallet.amount} #{wallet.currency_code}"
  end

  def displayed_amount(amount)
    return '-' unless amount
    return 0.0 if amount.zero?

    format('%+g', amount)
  end
end
