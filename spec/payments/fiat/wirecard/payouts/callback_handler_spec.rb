describe Payments::Fiat::Wirecard::Payouts::CallbackHandler do
  include_context 'wirecard_env'

  subject { described_class.call(response) }

  let(:customer) { create(:customer) }
  let(:entry_request) do
    create(
      :entry_request,
      customer: customer,
      currency: currency,
      origin: withdrawal
    )
  end
  let(:withdrawal) { create(:withdrawal, entry_request: nil) }
  let(:currency) { create(:currency, :primary) }
  let(:wallet) { create(:wallet, currency: currency) }
  let(:entry) do
    create(
      :entry,
      kind: Entry::WITHDRAW,
      amount: amount,
      wallet: wallet,
      entry_request: entry_request
    )
  end

  let(:response) do
    {
      'payment' => {
        'statuses' => {
          'status' => {
            'code' => code,
            'description' => description
          }
        },
        'transaction-state' => state,
        'transaction-id' => SecureRandom.hex(5),
        'request-id' => "#{entry_request.id}:#{Time.zone.now}"
      }
    }
  end

  before do
    # ignore job after new customer creating
    allow(Customers::Summaries::UpdateWorker).to receive(:perform_async)

    subject
  end

  context 'when request failed' do
    let(:code) { Payments::Fiat::Wirecard::Statuses::CANCELLED_STATUSES.sample }
    let(:state) { Payments::Fiat::Wirecard::TransactionStates::FAILED }
    let(:description) { 'Failed' }

    it 'rollback withdrawal' do
      expect(withdrawal.reload.status).to eq(Withdrawal::PENDING)
    end

    it 'store error message' do
      expect(withdrawal.reload.transaction_message).to eq(description)
    end
  end

  context 'when transaction completed' do
    let(:code) { '201.0000' }
    let(:state) { Payments::Fiat::Wirecard::TransactionStates::SUCCESSFUL }
    let(:description) { 'Created' }

    it 'sucseed withdrawal' do
      expect(withdrawal.reload.status).to eq(Withdrawal::SUCCEEDED)
    end

    it 'store transaction id' do
      expect(entry_request.reload.external_id).not_to be_empty
    end
  end
end
