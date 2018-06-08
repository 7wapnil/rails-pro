module BalanceHelper
  def wallet_balances_for(customer)
    customer.wallets.map { |wallet| wallet_balance(wallet) }.join(' / ')
  end

  def wallet_balance(wallet)
    "#{wallet.amount} #{wallet.currency_code}"
  end
end
