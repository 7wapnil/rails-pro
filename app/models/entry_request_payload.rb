class EntryRequestPayload
  include ActiveModel::Model

  attr_accessor :kind,
                :currency_code,
                :customer_id,
                :comment,
                :origin_type,
                :origin_id

  attr_reader :amount

  KINDS = EntryKinds::KINDS.keys.map(&:to_s)

  validates :amount, :kind, :currency_code, :customer_id, presence: true
  validates :amount, numericality: true
  validates :kind, inclusion: { in: KINDS }
  validates :currency_code,
            inclusion: { in: ->(_) { Currency.select(:code).map(&:code) } }

  validates_with EntryAmountValidator

  def customer
    @customer ||= Customer.find(customer_id)
  end

  def currency
    @currency ||= Currency.find_by!(code: @currency_code)
  end

  def amount=(value)
    @amount = numeric_value(value)
  end

  def origin
    origin_type
      .to_s
      .camelize
      .safe_constantize
      &.find(origin_id)
  end

  def to_json
    {
      customer_id: customer_id,
      kind: kind,
      amount: @amount,
      currency_code: currency_code
    }.to_json
  end

  private

  def numeric_value(value)
    return value.to_d if value.is_a?(Numeric)
    BigDecimal(value)
  rescue ArgumentError, TypeError
    value
  end
end
