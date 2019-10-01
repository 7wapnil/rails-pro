# frozen_string_literal: true

describe EntryRequests::Backoffice::Bets::Proceed do
  subject { described_class.call(bet, bet_params) }

  let(:customer_bonus) { create(:customer_bonus) }
  let(:customer) { create(:customer) }
  let(:currency) { create(:currency, :primary) }
  let!(:wallet) { create(:wallet, currency: currency, customer: customer) }
  let(:real_balance) { create(:balance, wallet: wallet) }
  let(:bet) { create(:bet, :with_placement_entry, customer: customer) }
  let(:bet_params) do
    {
      customer: customer,
      initiator: create(:user),
      comment: 'Won',
      settlement_status: status
    }
  end
  let(:status) { Bet::WON }

  before do
    allow(::WalletEntry::AuthorizationService).to receive(:call)
    subject
  rescue Bets::InvalidStatusError
  end

  context 'pending bet' do
    let(:bet) { create(:bet, status: Bet::INITIAL) }
    let(:status) { Bet::VOIDED }

    it 'does not call authorization service' do
      expect(::WalletEntry::AuthorizationService).not_to have_received(:call)
    end

    it 'bet is still pending' do
      expect(bet.reload.status).to eq(Bet::INITIAL)
    end
  end

  context 'won bet' do
    let(:bet) do
      create(:bet, :with_placement_entry, :settled, :won, customer: customer)
    end
    let(:status) { Bet::WON }

    it 'does not call authorization service' do
      expect(::WalletEntry::AuthorizationService).not_to have_received(:call)
    end
  end

  context 'lost bet' do
    let(:bet) do
      create(:bet, :with_placement_entry, :lost, customer: customer)
    end
    let(:status) { Bet::LOST }

    it 'does not call authorization service' do
      expect(::WalletEntry::AuthorizationService).not_to have_received(:call)
    end
  end

  context 'failed bet' do
    let(:bet) do
      create(:bet, customer: customer, settlement_status: nil)
    end
    let(:status) { Bet::VOIDED }

    it 'does not call authorization service' do
      expect(::WalletEntry::AuthorizationService).not_to have_received(:call)
    end
  end
end
