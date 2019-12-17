# frozen_string_literal: true

describe Bets::Cancel do
  subject { described_class.call(bet_leg: bet_leg, bet: bet) }

  let(:bet) do
    create(:bet, :settled, :won, :with_placement_entry)
  end
  let!(:bet_leg) do
    create(:bet_leg, bet: bet, settlement_status: bet_leg_settlement_status)
  end
  let(:bet_leg_settlement_status) { BetLeg::WON }
  let(:initial_value) { 10_000 }
  let!(:wallet) do
    create(:wallet, customer: bet.customer,
                    currency: bet.currency,
                    amount: initial_value,
                    real_money_balance: initial_value,
                    bonus_balance: 0)
  end

  include_context 'base_currency'

  before do
    allow(EntryRequests::ProcessingService).to receive(:call).and_call_original
  end

  context 'single bet' do
    let!(:expected_amount) do
      wallet.amount - bet.winning.amount + bet.placement_entry.amount.abs
    end

    it 'cancels placement and winning entries' do
      expect(EntryRequests::ProcessingService).to receive(:call).twice
      subject
    end

    it 'cancels bet' do
      subject
      expect(bet.reload).to be_cancelled_by_system
    end

    it 'updates wallet balance' do
      subject
      expect(wallet.reload.amount).to eq(expected_amount)
    end
  end

  context 'combo-bets' do
    let(:bet_status) { Bet::ACCEPTED }
    let(:settlement_status) { nil }
    let(:bet) do
      traits = [bet_status.to_sym, :with_placement_entry,
                settlement_status&.to_sym]
      create(:bet, *traits.compact, combo_bets: true)
    end

    context 'with unsettled bet leg' do
      let!(:unsettled_bet_leg) { create(:bet_leg, bet: bet) }
      let!(:expected_amount) { wallet.amount }

      it 'does not process eny entries requests' do
        expect(EntryRequests::ProcessingService).not_to receive(:call)
        subject
      end

      it 'keeps bet status' do
        subject
        expect(bet.reload).to be_accepted
      end

      it 'cancels bet leg' do
        subject
        expect(bet_leg.reload).to be_cancelled_by_system
      end

      it 'does not change wallet balance' do
        subject
        expect(wallet.reload.amount).to eq(expected_amount)
      end
    end

    context 'with lost bet leg and processing another bet leg' do
      let(:bet_status) { Bet::SETTLED }
      let(:settlement_status) { Bet::LOST }
      let(:bet_leg_settlement_status) { BetLeg::WON }
      let!(:lost_bet_leg) { create(:bet_leg, :lost, bet: bet) }
      let!(:expected_amount) { wallet.amount }

      it 'does not process eny entries requests' do
        expect(EntryRequests::ProcessingService).not_to receive(:call)
        subject
      end

      it 'keeps bet status' do
        subject
        expect(bet.reload).to be_settled
      end

      it 'keeps bet settlement status' do
        subject
        expect(bet.reload).to be_lost
      end

      it 'cancels bet leg' do
        subject
        expect(bet_leg.reload).to be_cancelled_by_system
      end

      it 'does not change wallet balance' do
        subject
        expect(wallet.reload.amount).to eq(expected_amount)
      end
    end

    context 'with won bet leg and processing lost bet leg' do
      let(:bet_status) { Bet::SETTLED }
      let(:settlement_status) { Bet::LOST }
      let(:bet_leg_settlement_status) { BetLeg::LOST }
      let!(:won_bet_leg) { create(:bet_leg, :won, bet: bet) }
      let!(:expected_amount) do
        wallet.amount + (bet.amount * won_bet_leg.odd_value)
                        .round(Bet::PRECISION)
      end

      it 'processes entries requests 3 times' do
        expect(EntryRequests::ProcessingService)
          .to receive(:call).at_least(3).times
        subject
      end

      it 'keeps bet status' do
        subject
        expect(bet.reload).to be_settled
      end

      it 'wins bet' do
        subject
        expect(bet.reload).to be_won
      end

      it 'cancels bet leg' do
        subject
        expect(bet_leg.reload).to be_cancelled_by_system
      end

      it 'updates wallet balance' do
        subject
        expect(wallet.reload.amount).to eq(expected_amount)
      end
    end

    context 'with voided bet leg and processing won bet leg' do
      let(:bet_status) { Bet::SETTLED }
      let(:settlement_status) { Bet::WON }
      let(:bet_leg_settlement_status) { BetLeg::WON }
      let!(:voided_bet_leg) { create(:bet_leg, :voided, bet: bet) }
      let!(:expected_amount) do
        wallet.amount - bet.winning.amount + bet.placement_entry.amount.abs
      end

      it 'processes entries requests twice' do
        expect(EntryRequests::ProcessingService).to receive(:call).twice
        subject
      end

      it 'keeps bet status' do
        subject
        expect(bet.reload).to be_settled
      end

      it 'voids bet' do
        subject
        expect(bet.reload).to be_voided
      end

      it 'cancels bet leg' do
        subject
        expect(bet_leg.reload).to be_cancelled_by_system
      end

      it 'updates wallet balance' do
        subject
        expect(wallet.reload.amount).to eq(expected_amount)
      end
    end

    context 'with voided bet leg and processing lost bet leg' do
      let(:bet_status) { Bet::SETTLED }
      let(:settlement_status) { Bet::LOST }
      let(:bet_leg_settlement_status) { BetLeg::LOST }
      let!(:voided_bet_leg) { create(:bet_leg, :voided, bet: bet) }
      let!(:expected_amount) do
        wallet.amount + bet.placement_entry.amount.abs
      end

      it 'processes entries requests once' do
        expect(EntryRequests::ProcessingService).to receive(:call).once
        subject
      end

      it 'keeps bet status' do
        subject
        expect(bet.reload).to be_settled
      end

      it 'voids bet' do
        subject
        expect(bet.reload).to be_voided
      end

      it 'cancels bet leg' do
        subject
        expect(bet_leg.reload).to be_cancelled_by_system
      end

      it 'updates wallet balance' do
        subject
        expect(wallet.reload.amount).to eq(expected_amount)
      end
    end

    context 'with won bet leg and processing another won bet leg' do
      let(:bet_status) { Bet::SETTLED }
      let(:settlement_status) { Bet::WON }
      let(:bet_leg_settlement_status) { BetLeg::WON }
      let!(:won_bet_leg) { create(:bet_leg, :won, bet: bet) }
      let!(:expected_amount) do
        wallet.amount -
          bet.winning.amount +
          (bet.amount * won_bet_leg.odd_value).round(Bet::PRECISION)
      end

      it 'processes entries requests 4 times' do
        expect(EntryRequests::ProcessingService)
          .to receive(:call).at_least(4).times
        subject
      end

      it 'keeps bet status' do
        subject
        expect(bet.reload).to be_settled
      end

      it 'wins bet' do
        subject
        expect(bet.reload).to be_won
      end

      it 'cancels bet leg' do
        subject
        expect(bet_leg.reload).to be_cancelled_by_system
      end

      it 'updates wallet balance' do
        subject
        expect(wallet.reload.amount).to eq(expected_amount)
      end
    end
  end
end
