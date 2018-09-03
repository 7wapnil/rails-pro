class MarketStateValidator < ActiveModel::Validator
  def validate(record)
    return unless options.key?(:restrictions)
    return unless record.status_changed?
    return if record.status_was.nil?

    change = record.status_change
    options[:restrictions].each do |rule|
      next unless rule[0].to_s == change[0]
      next unless rule[1].to_s == change[1]
      record.errors[:status] << I18n.t('errors.messages.wrong_market_state',
                                       initial_state: change[0],
                                       new_state: change[1])
    end
  end
end
