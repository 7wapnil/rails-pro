# frozen_string_literal: true

describe Payments::Fiat::Wirecard::Deposits::CallbackHandler do
  include_context 'wirecard_env'

  subject { described_class.call(response) }

  let(:customer) { create(:customer) }
  let(:entry_request) do
    create(
      :entry_request,
      customer: customer,
      currency: currency,
      origin: deposit
    )
  end
  let(:deposit) { create(:deposit) }
  let(:currency) { create(:currency, :primary) }
  let(:wallet) { create(:wallet, currency: currency) }
  let(:entry) do
    create(:entry, kind: Entry::DEPOSIT, amount: amount, wallet: wallet)
  end

  let(:response) do
    {
      'payment' => {
        'statuses' => {
          'status' => [{
            'code' => code,
            'description' => description
          }]
        },
        'transaction-state' => state,
        'transaction-id' => SecureRandom.hex(5),
        'card-token' => {
          'token-id' => SecureRandom.hex(10),
          'masked-account-number' => SecureRandom.hex(10)
        },
        'account-holder' => {
          'first-name' => Faker::Name.first_name,
          'last-name' => Faker::Name.last_name
        },
        'request-id' => "#{entry_request.id}:#{Time.zone.now}"
      }
    }
  end

  before do
    # ignore job after new customer creating
    allow(Customers::Summaries::UpdateWorker).to receive(:perform_async)
  end

  context 'when request canceled by customer' do
    let(:code) { Payments::Fiat::Wirecard::Statuses::CANCELLED_STATUSES.sample }
    let(:state) { Payments::Fiat::Wirecard::TransactionStates::FAILED }
    let(:description) { 'Canceled' }

    it 'raise Payments::CancelledError' do
      expect { subject }.to raise_error(Payments::CancelledError)
    end

    it 'fail entry request' do
      subject
    rescue Payments::CancelledError => _e
      expect(entry_request.reload.status).to eq(EntryRequest::FAILED)
    end

    it 'fail deposit' do
      subject
    rescue Payments::CancelledError => _e
      expect(deposit.reload.status).to eq(CustomerTransaction::FAILED)
    end
  end

  context 'when request failed' do
    let(:code) { '422.0001' }
    let(:state) { Payments::Fiat::Wirecard::TransactionStates::FAILED }
    let(:description) { 'Failed' }

    it 'raise Payments::CancelledError' do
      expect { subject }.to raise_error(Payments::FailedError)
    end

    it 'fail entry request' do
      subject
    rescue Payments::FailedError => _e
      expect(entry_request.reload.status).to eq(EntryRequest::FAILED)
    end

    it 'fail deposit' do
      subject
    rescue Payments::FailedError => _e
      expect(deposit.reload.status).to eq(CustomerTransaction::FAILED)
    end
  end

  context 'when transaction completed' do
    let(:code) { '201.0000' }
    let(:state) { Payments::Fiat::Wirecard::TransactionStates::SUCCESSFUL }
    let(:description) { 'Created' }

    before do
      allow(EntryRequests::DepositWorker).to receive(:perform_async)
    end

    it 'record payment details' do
      subject

      expect(deposit.reload.details)
        .to include('masked_account_number', 'token_id')
    end
  end
end
