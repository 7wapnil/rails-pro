class EntriesPrimer
  def self.random
    Random.new
  end

  def self.create_entry!(rule:, currency:, customer:)
    request = EntryRequest.create!(
      kind: rule.kind,
      currency: currency,
      customer: customer,
      amount: random.rand(rule.min_amount..rule.max_amount).round(2),
      initiator: customer,
      comment: 'Prime data'
    )

    WalletEntry::Service.call(request)
  end
end

puts 'Creating Deposits ...'

Customer
  .order(Arel.sql('RANDOM()'))
  .limit(150)
  .find_each batch_size: 50 do |customer|

  EntriesPrimer.random.rand(1..3).times do
    currency = Currency.order(Arel.sql('RANDOM()')).select(:id, :code).first

    next if customer.wallets.where(currency: currency).exists?

    rule = EntryCurrencyRule.find_by!(currency: currency, kind: :deposit)

    EntriesPrimer.create_entry!(
      rule: rule,
      currency: currency,
      customer: customer
    )
  end
end

puts 'Simulating Customer activity ...'

Wallet.find_each batch_size: 50 do |wallet|
  bet_rule = EntryCurrencyRule.find_by!(currency: wallet.currency, kind: :bet)
  win_rule = EntryCurrencyRule.find_by!(currency: wallet.currency, kind: :win)

  EntriesPrimer.random.rand(2..5).times do
    kind = %i[bet win].sample
    rule = binding.local_variable_get "#{kind}_rule"

    EntriesPrimer.create_entry!(
      rule: rule,
      currency: wallet.currency,
      customer: wallet.customer
    )
  end
end
