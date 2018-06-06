class EntryRequestPayload
  include ActiveModel::Model

  attr_accessor :customer, :kind, :amount, :currency, :customer_id

  KINDS = EntryRequest.kinds.keys

  validates :amount, :kind, :customer, :currency, presence: true
  validates :amount, numericality: true
  validates :kind, inclusion: { in: KINDS }
  validates :currency, inclusion: { in: Wallet.currencies.keys }

  def initialize(attributes = {})
    super(attributes)
    @customer ||= Customer.find_by(id: attributes[:customer_id])
  end

  KINDS.each do |kind|
    define_method "#{kind}?" do
      @kind == kind
    end
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
