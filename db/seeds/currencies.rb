puts 'Checking currencies ...'

currency_mapping = [
  { name: 'Euro', code: 'EUR', primary: true },
  { name: 'Swedish Kronor', code: 'SEK' },
  { name: 'BitCoin', code: 'mBTC' },
  { name: 'Ethereum', code: 'ETH' }
]

entry_currency_rule_ranges = {
  deposit:          { min:  10,    max:  1_000  },
  win:              { min:  1,     max:  10_000 },
  internal_debit:   { min:  1,     max:  1_000  },
  withdraw:         { min: -1_000, max: -10     },
  bet:              { min: -1_000, max: -1      },
  internal_credit:  { min: -1_000, max: -1      }
}

currency_mapping.each do |payload|
  Currency.find_or_create_by(name: payload[:name]) do |currency|
    currency.code = payload[:code]
    currency.primary = payload[:primary] || false
  end
end

Currency.select(:id).find_each(batch_size: 10) do |currency|
  EntryKinds::KINDS.keys.each do |kind|
    EntryCurrencyRule.find_or_create_by(currency: currency, kind: kind) do |r|
      r.min_amount = entry_currency_rule_ranges[kind][:min]
      r.max_amount = entry_currency_rule_ranges[kind][:max]
    end
  end
end
