# frozen_string_literal: true

describe Payments::Crypto::CoinsPaid::Payouts::RequestHandler do
  subject { described_class.call(transaction) }

  let(:client_double) { double }

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
  let(:details) { { 'address' => Faker::Bitcoin.address } }
  let(:request_double) { double }

  it 'authorizes payment' do
    allow(::Payments::Crypto::CoinsPaid::Client)
      .to receive(:new).and_return(client_double)
    allow(request_double).to receive(:code).and_return(201)

    expect(client_double)
      .to receive(:authorize_payout).and_return(request_double)

    subject
  end

  context 'request successful' do
    before do
      allow(::Payments::Crypto::CoinsPaid::Client)
        .to receive(:new).and_return(client_double)
      allow(request_double).to receive(:code).and_return(201)
      allow(client_double)
        .to receive(:authorize_payout).and_return(request_double)
    end

    it 'does not update withdrawal' do
      expect_any_instance_of(Withdrawal).not_to receive(:update)
    end
  end

  context 'request failed' do
    let(:request) do
      <<-EXAMPLE_JSON
      {
        "errors": {
          "amount": "The amount must be at least 0.001."
        }
      }
      EXAMPLE_JSON
    end

    before do
      allow(::Payments::Crypto::CoinsPaid::Client)
        .to receive(:new).and_return(client_double)
      allow(request_double).to receive(:code).and_return(500)
      allow(client_double)
        .to receive(:authorize_payout).and_return(request_double)
      allow(request_double)
        .to receive(:body).and_return(request)
    end

    it 'updates withdrawal' do
      expect(withdrawal.status).to eq(Withdrawal::PENDING)

      subject
    rescue ::Withdrawals::PayoutError
    end

    it 'raises error' do
      expect { subject }.to raise_error(::Withdrawals::PayoutError)
    end
  end
end
