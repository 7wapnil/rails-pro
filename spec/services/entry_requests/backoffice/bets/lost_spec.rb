# frozen_string_literal: true

describe EntryRequests::Backoffice::Bets::Lost do
  include_context 'manual settlement'

  subject { described_class.call(**bet_params) }

  let(:bet_params) do
    {
      bet: bet,
      initiator: create(:user),
      comment: 'Lost'
    }
  end

  context 'placement bet' do
    let(:bet) { placed_bet }
    let!(:expected_amount) { wallet.real_money_balance }

    before { subject }

    it 'settles bet' do
      expect(bet.reload).to be_lost
    end

    it 'doesnt change balance' do
      expect(wallet.reload.real_money_balance).to eq(expected_amount)
    end
  end

  context 'voided bet' do
    let(:bet) { voided_bet }
    let(:real_balance_amount) { wallet.real_money_balance }
    let(:voided_amount) { placement_entry.real_money_amount.abs }
    let!(:expected_amount) do
      real_balance_amount - voided_amount
    end

    before { subject }

    it 'cuts voided amount' do
      expect(wallet.reload.real_money_balance).to eq(expected_amount)
    end
  end

  context 'won bet' do
    let(:bet) { won_bet }
    let(:real_balance_amount) { wallet.real_money_balance }
    let(:winning_amount) { winning_entry.real_money_amount }
    let!(:expected_amount) do
      real_balance_amount - winning_amount
    end

    before { subject }

    it 'cuts won amount' do
      expect(wallet.reload.real_money_balance).to eq(expected_amount)
    end
  end
end
