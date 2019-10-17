# frozen_string_literal: true

describe Payments::Fiat::SafeCharge::Payouts::RequestHandler do
  include_context 'safecharge_env'

  subject { described_class.call(transaction) }

  let(:transaction) do
    ::Payments::Transactions::Payout.new(
      id: entry_request.id,
      method: Payments::Methods::NETELLER,
      withdrawal: withdrawal,
      details: { 'user_payment_option_id' => payment_option_id },
      customer: entry_request.customer,
      currency_code: entry_request.currency.code,
      amount: entry_request.amount
    )
  end

  let(:customer) { create(:customer) }
  let(:entry_request) { create(:entry_request, customer: customer) }
  let(:amount) { entry_request.amount }
  let(:payment_option_id) { Faker::Number.number(6).to_s }
  let(:withdrawal) { create(:withdrawal, entry_request: entry_request) }

  let(:payout_payload) { {} }
  let(:payout_response) do
    OpenStruct.new(
      'ok?': true,
      **payout_payload.symbolize_keys
    )
  end
  let(:approve_payload) { {} }
  let(:approve_response) do
    OpenStruct.new(
      'ok?': true,
      **approve_payload.symbolize_keys
    )
  end

  before do
    # ignore job after new customer creating
    allow(Customers::Summaries::UpdateWorker).to receive(:perform_async)
    allow_any_instance_of(Payments::Fiat::SafeCharge::Client)
      .to receive(:authorize_payout)
      .and_return(payout_response)
    allow_any_instance_of(Payments::Fiat::SafeCharge::Client)
      .to receive(:approve_payout)
      .and_return(approve_response)
  end

  context 'when request completed' do
    let(:payout_payload) do
      JSON.parse(
        file_fixture('payments/fiat/safe_charge/payout.json').read
      )
    end
    let(:approve_payload) do
      JSON.parse(
        file_fixture('payments/fiat/safe_charge/approve.json').read
      )
    end

    before { subject }

    it { is_expected.to be_truthy }

    it 'changes withdrawal status' do
      expect(withdrawal.reload).to be_succeeded
    end
  end

  context 'when something went wrong' do
    let(:payout_payload) do
      JSON.parse(
        file_fixture('payments/fiat/safe_charge/payout_failed.json').read
      )
    end
    let(:message) { 'SafeCharge: Invalid checksum' }

    it 'raise payment error' do
      expect { subject }.to raise_error(Withdrawals::PayoutError)
    end

    it 'rollback withdrawal status' do
      subject
    rescue Withdrawals::PayoutError => _e
      expect(withdrawal.reload).to be_pending
    end

    it 'stores rejection reason' do
      subject
    rescue Withdrawals::PayoutError => _e
      expect(withdrawal.reload.transaction_message).to eq(message)
    end
  end
end
