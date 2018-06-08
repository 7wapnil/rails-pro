puts 'Creating Deposits ...'

random = Random.new

Customer
  .order(Arel.sql('RANDOM()'))
  .limit(150)
  .find_each batch_size: 50 do |customer|

  random.rand(1..3).times do
    currency = Currency.order(Arel.sql('RANDOM()')).select(:id, :code).first

    next if customer.wallets.where(currency: currency).exists?

    rule = EntryCurrencyRule.find_by!(currency: currency, kind: :deposit)
    request = EntryRequest.create!(
      payload: {
        kind: :deposit,
        currency_code: currency.code,
        customer_id: customer.id,
        amount: random.rand(rule.min_amount..rule.max_amount).round(2).to_f
      }
    )

    WalletEntry::Service.call(request)
  end
end
