puts 'Checking currencies ...'

currency_mapping = [
  { name: 'Euro', code: 'EUR', primary: true, kind: Currency::FIAT },
  { name: 'US dollar', code: 'USD', kind: Currency::FIAT },
  { name: 'Pound sterling', code: 'GBP', kind: Currency::FIAT },
  { name: 'Australian dollar', code: 'AUD', kind: Currency::FIAT },
  { name: 'Norwegian krone', code: 'NOK', kind: Currency::FIAT },
  { name: 'Danish krone', code: 'DKK', kind: Currency::FIAT },
  { name: 'Swedish Kronor', code: 'SEK', kind: Currency::FIAT },
  { name: 'Canadian dollar', code: 'CAD', kind: Currency::FIAT },
  { name: 'Russian rouble', code: 'RUB', kind: Currency::FIAT },
  { name: 'BitCoin', code: 'mBTC', kind: Currency::CRYPTO }
]

entry_currency_rule_ranges = {
  deposit:           { min:  10,     max:  1_000  },
  win:               { min:  1,      max:  10_000 },
  internal:          { min:  -1_000, max:  1_000  },
  withdraw:          { min: -1_000,  max: -10     },
  bet:               { min: -1_000,  max: -1      },
  refund:            { min: 0,       max: 10_000  },
  rollback:          { min: -10_000, max: 10_000  },
  system_bet_cancel: { min: -10_000, max: 10_000  }
}

currency_mapping.each do |payload|
  Currency.find_or_create_by(name: payload[:name]) do |currency|
    currency.code = payload[:code]
    currency.primary = payload[:primary] || false
    currency.kind = payload[:kind]
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
