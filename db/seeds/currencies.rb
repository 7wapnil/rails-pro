puts 'Checking currencies ...'

currency_mapping = [
  { name: 'Euro', code: 'EUR', primary: true },
  { name: 'Swedish Kronor', code: 'SEK' },
  { name: 'BitCoin', code: 'mBTC' },
  { name: 'Ethereum', code: 'ETH' }
]

currency_mapping.each do |payload|
  Currency.find_or_create_by(name: payload[:name]) do |currency|
    currency.code = payload[:code]
    currency.primary = payload[:primary] || false
  end
end
