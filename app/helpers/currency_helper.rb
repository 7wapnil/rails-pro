module CurrencyHelper
  def currencies_with_primary_for(customer)
    return customer.currencies if customer.currencies.include?(Currency.primary)

    customer.currencies.to_a << Currency.primary
  end
end
