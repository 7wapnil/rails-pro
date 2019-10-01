# frozen_string_literal: true

describe EntryRequests::Backoffice::Bets::Won do
  include_context 'manual settlement'

  subject { described_class.call(**bet_params) }

  let(:bet_params) do
    {
      bet: bet,
      initiator: create(:user),
      comment: 'Won'
    }
  end

  let(:real_balance_amount) { wallet.real_money_balance }
  let(:placed_amount) { placement_entry.real_money_amount.abs }

  context 'voided bet' do
    let(:bet) { rejected_bet }
    let(:voided_amount) { placement_entry.real_money_amount.abs }
    let!(:expected_amount) do
      real_balance_amount + bet.odd_value * placed_amount - voided_amount
    end

    before { subject }

    it 'adds won amount without voided amount' do
      expect(wallet.reload.real_money_balance.to_f.round(2))
        .to eq(expected_amount.to_f.round(2))
    end
  end

  context 'lost bet' do
    let(:bet) { settled_bet }
    let(:winning_amount) { bet.odd_value * placed_amount }
    let!(:expected_amount) do
      real_balance_amount + winning_amount
    end

    before { subject }

    it 'adds won amount' do
      expect(wallet.reload.real_money_balance.to_f.round(2))
        .to eq(expected_amount.to_f.round(2))
    end
  end
end
