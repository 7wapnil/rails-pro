# frozen_string_literal: true

describe EntryRequests::BetRefundService do
  subject do
    described_class.call(
      entry_request: entry_request,
      message: message,
      code: code,
      details: details
    )
  end

  let(:message) { 'Rejected' }
  let(:code) { 'rejection_code' }
  let(:details) { {} }

  let!(:currency) { create(:currency, :primary) }
  let!(:wallet) do
    create(:wallet, :brick, currency: currency,
                            real_money_balance: 200,
                            bonus_balance: 0)
  end
  let!(:balance_amount_before) { wallet.real_money_balance }

  let(:odd) { create(:odd, :active, market: market) }
  let(:market) { create(:event, :with_market, :upcoming).markets.sample }
  let(:bet_status) { Bet::SENT_TO_EXTERNAL_VALIDATION }
  let!(:bet) do
    create(:bet, :with_placement_entry, customer: wallet.customer,
                                        currency: currency,
                                        amount: 100,
                                        status: bet_status,
                                        odd: odd)
  end
  let(:entry_request) do
    EntryRequests::Factories::BetRefund.call(bet: bet, comment: message)
  end

  context 'with new entry request' do
    let(:bet_leg) { bet.bet_legs.first }
    let(:details) do
      {
        bet_leg.id.to_s => {
          notification_message: message,
          notification_code: code
        }
      }
    end

    before do
      allow(WebSocket::Client.instance).to receive(:trigger_bet_update)

      subject
    end

    it 'updates bet status as rejected' do
      expect(bet).to be_rejected
    end

    it 'stores rejection reason' do
      expect(bet)
        .to have_attributes(
          notification_message: message,
          notification_code: code
        )
    end

    it 'stores rejection reason in failed bet leg' do
      expect(bet_leg.reload)
        .to have_attributes(
          notification_message: message,
          notification_code: code
        )
    end

    it 'makes refund' do
      expect(wallet.reload.real_money_balance)
        .to eq(balance_amount_before + entry_request.amount)
    end

    it 'notifies betslip' do
      expect(WebSocket::Client.instance)
        .to have_received(:trigger_bet_update)
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
      bet.update(status: Bet::SENT_TO_INTERNAL_VALIDATION)

      subject
    end

    it 'does not change balance' do
      expect(wallet.reload.real_money_balance).to eq(balance_amount_before)
    end
  end
end
