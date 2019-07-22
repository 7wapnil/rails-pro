# frozen_string_literal: true

describe ::Payments::Crypto::CoinsPaid::Provider do
  subject { described_class.new(transaction) }

  let(:customer) { create(:customer, :ready_to_bet, type: :crypto) }
  let(:bonus_code) { nil }

  def transaction
    @transaction ||= ::Payments::Transactions::Deposit.new(
      method: Payments::Methods::BITCOIN,
      customer: customer,
      currency_code: customer.wallet.currency.code,
      amount: rand(10..100),
      bonus_code: bonus_code
    )
  end

  before do
    allow(::CryptoAddresses::GetOrCreate).to receive(:call)
    allow(::Payments::Crypto::CoinsPaid::Payouts::RequestHandler)
      .to receive(:call)
  end

  %i[receive_deposit_address process_payout].each do |method|
    it "subject to respond to #{method}" do
      expect(subject).to respond_to(method)
    end
  end
end
