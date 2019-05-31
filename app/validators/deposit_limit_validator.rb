class DepositLimitValidator < ActiveModel::Validator
  # requires a record to be Payments::Transaction instance
  def validate(record)
    return unless record.customer

    customer_limits = deposit_limits(record.customer, record.currency)
    return unless customer_limits

    time_range = (customer_limits.range.days.ago...Time.current)
    existing_volume = existing_deposits_volume(record.customer, time_range)
    potential_deposits_total = existing_volume + record.amount
    return if potential_deposits_total < customer_limits.value

    record.errors[:amount] << 'Deposit limit is not available'
  end

  private

  def deposit_limits(customer, currency)
    customer.deposit_limits.find_by(currency: currency)
  end

  def existing_deposits_volume(customer, time_range)
    customer
      .entry_requests
      .where(
        status: [EntryRequest::PENDING, EntryRequest::SUCCEEDED],
        kind: EntryRequest::DEPOSIT,
        created_at: time_range
      )
      .sum(:amount)
  end
end
