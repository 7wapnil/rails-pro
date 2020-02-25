class MarketStateValidator < ActiveModel::Validator
  def validate(record)
    return unless options.key?(:restrictions)
    return unless record.status_changed?
    return if record.status_was.nil?

    change = record.status_change
    return unless options[:restrictions].any? do |restriction|
      restriction[0].to_s == change[0] && restriction[1].to_s == change[1]
    end

    record.errors[:status] << error_message(change)
  end

  private

  def error_message(market_status_change)
    I18n.t('internal.errors.messages.wrong_market_state',
           initial_state: market_status_change[0],
           new_state: market_status_change[1])
  end
end
