# frozen_string_literal: true

puts 'Checking currencies ...'

currency_mapping = [
  {
    name: 'Euro',
    code: 'EUR',
    primary: true,
    kind: Currency::FIAT,
    exchange_rate: 1
  },
  { name: 'US dollar', code: 'USD', kind: Currency::FIAT },
  { name: 'Pound sterling', code: 'GBP', kind: Currency::FIAT },
  { name: 'Australian dollar', code: 'AUD', kind: Currency::FIAT },
  { name: 'Norwegian krone', code: 'NOK', kind: Currency::FIAT },
  { name: 'Danish krone', code: 'DKK', kind: Currency::FIAT },
  { name: 'Swedish Kronor', code: 'SEK', kind: Currency::FIAT },
  { name: 'Canadian dollar', code: 'CAD', kind: Currency::FIAT },
  { name: 'Russian rouble', code: 'RUB', kind: Currency::FIAT },
  { name: 'BitCoin', code: Currencies::Crypto::M_BTC, kind: Currency::CRYPTO },
  {
    name: 'Testnet BitCoin',
    code: Currencies::Crypto::M_TBTC,
    kind: Currency::CRYPTO,
    exchange_rate: 1
  }
]

entry_currency_rule_ranges = {
  EntryKinds::DEPOSIT => { min: 0, max: 100_000_000 },
  EntryKinds::WIN => { min: 0, max: 100_000_000 },
  EntryKinds::WITHDRAW => { min: -100_000_000, max: 0 },
  EntryKinds::BET => { min: -100_000_000, max: 0 },
  EntryKinds::REFUND => { min: 0, max: 100_000_000 },
  EntryKinds::ROLLBACK => { min: -100_000_000, max: 100_000_000 },
  EntryKinds::SYSTEM_BET_CANCEL => { min: -100_000_000, max: 100_000_000 },
  EntryKinds::BONUS_CONVERSION => { min: 0, max: 100_000_000 },
  EntryKinds::BONUS_CHANGE => { min: -100_000_000, max: 100_000_000 },
  EntryKinds::MANUAL_BET_CANCEL => { min: 0, max: 100_000_000 },
  EntryKinds::MANUAL_BET_PLACEMENT => { min: 0, max: 100_000_000 },
  EntryKinds::EVERY_MATRIX_WAGER => { min: -100_000_000, max: 0 },
  EntryKinds::EVERY_MATRIX_RESULT => { min: 0, max: 100_000_000 },
  EntryKinds::EVERY_MATRIX_ROLLBACK => { min: 0, max: 100_000_000 }
}.symbolize_keys

currency_mapping.each do |payload|
  Currency.find_or_create_by(code: payload[:code]) do |currency|
    currency.code = payload[:code]
    currency.name = payload[:name]
    currency.primary = payload[:primary] || false
    currency.kind = payload[:kind]
    currency.exchange_rate = payload[:exchange_rate]
  end
end

Currency.select(:id).find_each(batch_size: 10) do |currency|
  EntryKinds::KINDS.keys.each do |kind|
    EntryCurrencyRule.find_or_create_by(currency: currency, kind: kind) do |r|
      r.min_amount = entry_currency_rule_ranges.dig(kind, :min) || 0
      r.max_amount = entry_currency_rule_ranges.dig(kind, :max) || 0
    end
  end
end
