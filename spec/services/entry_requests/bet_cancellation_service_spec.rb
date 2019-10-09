# frozen_string_literal: true

describe EntryRequests::BetCancellationService do
  subject do
    described_class.call(
      entry_request: entry_request,
      status_code: code
    )
  end

  let(:code) { Mts::Codes::SUCCESSFUL_CODE }
  let(:message) { 'Cancelled' }
  let!(:currency) { create(:currency, :primary) }
  let(:entry) { create(:entry, wallet: wallet, amount: -100) }
  let!(:bet) do
    create(:bet, :sent_to_external_validation, placement_entry: entry,
                                               validation_ticket_id: ticket_id,
                                               currency: currency)
  end
  let!(:ticket_id) { "MTS_Test_#{Faker::Number.number(13)}" }
  let!(:wallet) do
    create(:wallet, :brick, currency: currency,
                            real_money_balance: 200,
                            bonus_balance: 0)
  end
  let!(:balance_amount_before) { wallet.real_money_balance }

  let(:entry_request) do
    EntryRequests::Factories::Refund.call(entry: bet.entry, comment: message)
  end

  context 'with new entry request' do
    before { subject }

    it 'updates bet status as cancelled' do
      expect(bet).to be_cancelled
    end

    it 'makes refund' do
      expect(wallet.reload.real_money_balance)
        .to eq(balance_amount_before + entry_request.amount)
    end
  end

  context 'with failed entry request' do
    before do
      entry_request.update(status: EntryRequest::FAILED)
      allow(WalletEntry::AuthorizationService).to receive(:call)

      subject
    end

    it 'does not make refund' do
      expect(WalletEntry::AuthorizationService).not_to have_received(:call)
    end

    it 'does not change balance' do
      expect(wallet.reload.real_money_balance).to eq(balance_amount_before)
    end
  end

  context 'already refunded' do
    before do
      create(:entry, entry_request: entry_request)

      subject
    end

    it 'does not change balance' do
      expect(wallet.reload.real_money_balance).to eq(balance_amount_before)
    end
  end

  context 'with invalid bet status' do
    before do
      bet.update(status: Bet::VALIDATED_INTERNALLY)

      subject
    end

    it 'does not change bet status' do
      expect(bet.reload).to be_validated_internally
    end

    it 'does not change balance' do
      expect(wallet.reload.real_money_balance).to eq(balance_amount_before)
    end
  end

  context 'with unsuccessful status code' do
    let(:code) { -2015 }

    before { subject }

    it 'change status to pending mts cancellation' do
      expect(bet.reload).to be_pending_mts_cancellation
    end

    it 'makes refund' do
      expect(wallet.reload.real_money_balance)
        .to eq(balance_amount_before + entry_request.amount)
    end
  end
end
