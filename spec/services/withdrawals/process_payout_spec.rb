# frozen_string_literal: true

describe Withdrawals::ProcessPayout do
  subject { described_class.call(withdrawal) }

  let(:withdrawal) { create(:withdrawal) }
  let(:entry_request) { withdrawal.entry_request }
  let(:entry) { withdrawal.entry }

  include_context 'frozen_time'

  context 'valid payout request' do
    before do
      allow(::Payments::Transactions::Payout)
        .to receive(:new)
        .with(
          id: entry_request.id,
          method: entry_request.mode,
          customer: entry_request.customer,
          currency_code: entry_request.currency.code,
          amount: entry_request.amount.abs.to_d,
          withdrawal: withdrawal,
          details: withdrawal.details
        )
        .and_return(:transaction)
      allow(::Payments::Payout).to receive(:call)

      subject
    end

    it 'performs payout' do
      expect(::Payments::Payout).to have_received(:call)
    end

    it 'confirm withdrawal entry' do
      expect(entry.reload.confirmed_at).to eq(Time.zone.now)
    end
  end

  context 'without reduce balance entry' do
    let(:entry_request) { create(:entry_request, :withdraw) }
    let(:withdrawal) do
      create(:withdrawal, entry_request: entry_request,
                          details: { paymentOptionId: '1' })
    end
    let(:error_message) do
      "base: #{I18n.t('errors.messages.withdrawal.invalid_withdrawal')}"
    end

    it 'raise transaction validation error' do
      expect { subject }.to raise_error(Payments::InvalidTransactionError)
    end
  end
end
