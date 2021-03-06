class EntryAmountValidator < ActiveModel::Validator
  # requires a record to be Entry instance
  def validate(record)
    rule = EntryCurrencyRule.find_by(currency: record.currency,
                                     kind: record.kind)

    return unless rule
    return if record.amount.in?(rule.min_amount..rule.max_amount)

    record.errors[:amount] << I18n.t('errors.messages.entry_amount_between',
                                     kind: record.kind,
                                     min_amount: rule.min_amount.abs,
                                     max_amount: rule.max_amount.abs,
                                     currency: record.currency.code)
  end
end
