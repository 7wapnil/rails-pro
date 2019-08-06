# frozen_string_literal: true

describe Payments::Crypto::Payout do
  subject { described_class.call(transaction) }

  let(:transaction) do
    ::Payments::Transactions::Payout.new(
      id: entry_request.id,
      method: entry_request.mode,
      customer: entry_request.customer,
      currency_code: entry_request.currency.code,
      amount: entry_request.amount.abs.to_d,
      withdrawal: withdrawal,
      details: withdrawal.details
    )
  end
  let!(:entry_request) do
    create(:entry_request, :withdrawal, mode: EntryRequest::BITCOIN)
  end
  let!(:withdrawal) do
    create(:withdrawal, entry_request: entry_request, details: details)
  end

  context 'valid transaction' do
    let(:details) { { 'address' => Faker::Bitcoin.address } }

    it 'calls process payout' do
      expect_any_instance_of(::Payments::Crypto::CoinsPaid::Provider)
        .to receive(:process_payout)

      subject
    end
  end

  context 'invalid transaction' do
    let(:details) { }
    it 'raises error on invalid transaction' do
      expect{ subject }.to raise_error(Payments::InvalidTransactionError)
    end
  end
end
