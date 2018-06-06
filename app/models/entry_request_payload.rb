class EntryRequestPayload
  include ActiveModel::Model

  attr_accessor :amount, :kind, :currency, :customer_id

  KINDS = EntryKinds::KINDS.keys.map(&:to_s)

  validates :amount, :kind, :currency, :customer_id, presence: true
  validates :amount, numericality: true
  validates :kind, inclusion: { in: KINDS }
  validates :currency, inclusion: { in: Wallet.currencies.keys }

  KINDS.each do |kind|
    define_method "#{kind}?" do
      @kind == kind
    end
  end

  def customer
    @customer ||= Customer.find(customer_id)
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
