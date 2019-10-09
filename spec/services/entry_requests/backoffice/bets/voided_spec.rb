# frozen_string_literal: true

describe EntryRequests::Backoffice::Bets::Voided do
  include_context 'manual settlement'

  subject { described_class.call(**bet_params) }

  let(:user) { create(:user) }
  let(:bet_params) do
    {
      bet: bet,
      initiator: user,
      comment: 'Void'
    }
  end

  let(:real_balance_amount) { wallet.real_money_balance }
  let(:placement_amount) { placement_entry.real_money_amount.abs }

  context 'placement bet' do
    let(:bet) { placed_bet }
    let!(:expected_amount) { real_balance_amount + placement_amount }

    before { subject }

    it 'voids placed amount' do
      expect(wallet.reload.real_money_balance).to eq(expected_amount)
    end
  end

  context 'won bet' do
    let(:bet) { won_bet }
    let(:winning_amount) { winning_entry.real_money_amount }
    let!(:expected_amount) do
      real_balance_amount + placement_amount - winning_amount
    end

    before { subject }

    it 'voids placed and won amount' do
      expect(wallet.reload.real_money_balance).to eq(expected_amount)
    end
  end

  context 'track settlement details' do
    let(:bet) { placed_bet }
    let!(:entry) { placement_entry }

    before { subject }

    it 'doesnt change bet_settlement_status_achieved_at' do
      expect(bet.reload.bet_settlement_status_achieved_at).to be_truthy
    end

    it 'sets current user as an initiator' do
      expect(bet.entry_requests.last.initiator).to eq(user)
    end
  end
end
