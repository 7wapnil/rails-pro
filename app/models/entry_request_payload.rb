class EntryRequestPayload
  include ActiveModel::Model

  attr_accessor :kind, :currency, :customer_id
  attr_writer :amount

  KINDS = EntryKinds::KINDS.keys.map(&:to_s)

  validates :amount, :kind, :currency, :customer_id, presence: true
  validates :amount, numericality: true
  validates :kind, inclusion: { in: KINDS }
  validates :currency, inclusion: { in: ->(_) { Currency.select(:code).map(&:code) } }

  KINDS.each do |kind|
    define_method "#{kind}?" do
      @kind == kind
    end
  end

  def customer
    @customer ||= Customer.find(customer_id)
  end

  def amount
    @amount.is_a?(Numeric) ? @amount.to_d : @amount
  end

  def to_json
    {
      customer_id: @customer&.id,
      kind: @kind,
      amount: @amount,
      currency: @currency
    }.to_json
  end
end
