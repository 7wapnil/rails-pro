# frozen_string_literal: true

describe ::Payments::Crypto::CoinsPaid::Provider do
  include_context 'crypto_deposit_transaction'

  subject { described_class.new(transaction) }

  before do
    allow(::Payments::Crypto::CoinsPaid::Deposits::RequestHandler)
      .to receive(:call)
    allow(::Payments::Crypto::CoinsPaid::Payouts::RequestHandler)
      .to receive(:call)
  end

  %i[receive_deposit_address process_payout].each do |method|
    it "subject to respond to #{method}" do
      expect(subject).to respond_to(method)
    end
  end
end
