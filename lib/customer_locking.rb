class CustomerLocking
  attr_reader :locked,
              :reason,
              :date

  def initialize(customer)
    @customer = customer
    @locked = @customer.locked
    @reason = build_reason
    @date = build_date
  end

  def to_h
    {
      locked: @locked,
      reason: @reason,
      date: @date
    }
  end

  private

  def build_reason
    return unless @customer.lock_reason

    I18n.t("lock_reasons.#{@customer.lock_reason}")
  end

  def build_date
    return unless @customer.locked

    return I18n.t('infinite') unless @customer.locked_until

    I18n.l(@customer.locked_until, format: :date_picker)
  end
end
