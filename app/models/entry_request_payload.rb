class EntryRequestPayload
  include ActiveModel::Model

  attr_accessor :kind, :currency_code, :customer_id
  attr_writer :amount

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

  def amount
    @amount.is_a?(Numeric) ? @amount.to_d : @amount
  end

  def to_json
    {
      customer_id: @customer&.id,
      kind: @kind,
      amount: @amount,
      currency_code: @currency&.code
    }.to_json
  end
end
