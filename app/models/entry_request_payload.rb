class EntryRequestPayload
  include ActiveModel::Validations

  attr_reader :customer, :kind, :amount, :currency

  KINDS = EntryRequest.kinds.keys

  validates :amount, :kind, :customer, :currency, presence: true
  validates :amount, numericality: true
  validates :kind, inclusion: { in: KINDS }
  validates :currency, inclusion: { in: Wallet.currencies.keys }

  # validates_with DepositRequestValidator, if: :deposit?
  # validates_with WinningRequestValidator, if: :winning?
  # validates_with InternalDebitRequestValidator, if: :internal_debit?
  # validates_with WithdrawRequestValidator, if: :withdraw?
  # validates_with BetRequestValidator, if: :bet?
  # validates_with InternalCreditRequestValidator, if: :internal_credit?

  def initialize(payload)
    @customer = Customer.find_by(id: payload['customer_id'])
    @kind = payload['kind']
    @amount = payload['amount']
    @currency = payload['currency']
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
