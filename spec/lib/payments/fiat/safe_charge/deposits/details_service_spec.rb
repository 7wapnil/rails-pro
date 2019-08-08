# frozen_string_literal: true

describe Payments::Fiat::SafeCharge::Deposits::DetailsService do
  include_context 'safecharge_env'

  subject { described_class.call(params) }

  let(:params) do
    {
      entry_request: entry_request,
      field: SecureRandom.hex(5)
    }
  end
  let(:entry_request) { create(:entry_request, mode: mode, origin: deposit) }
  let(:deposit) { create(:deposit) }

  before do
    # ignore job after new customer creating
    allow(Customers::Summaries::UpdateWorker).to receive(:perform_async)
  end

  context 'when Neteller' do
    let(:mode) { Payments::Methods::NETELLER }

    before { subject }

    it 'store account_id' do
      expect(deposit.reload.details).to include('account_id')
    end
  end

  context 'when Skrill' do
    let(:mode) { Payments::Methods::SKRILL }

    before { subject }

    it 'store email' do
      expect(deposit.reload.details).to include('email')
    end
  end

  context 'when credit card' do
    let(:mode) { Payments::Methods::CREDIT_CARD }

    before { subject }

    it 'store last four digits' do
      expect(deposit.reload.details).to include('last_four_digits')
    end
  end
end
