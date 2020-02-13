# frozen_string_literal: true

describe EntryRequests::Backoffice::Bets::Won do
  include_context 'manual settlement'

  subject { described_class.call(**bet_params) }

  let(:user) { create(:user) }
  let(:bet_params) do
    {
      bet: bet,
      initiator: user,
      comment: 'Won'
    }
  end

  let(:real_balance_amount) { wallet.real_money_balance }
  let(:placed_amount) { placement_entry.real_money_amount.abs }

  it 'recalculates bonus rollover' do
    subject
    expect(bet.reload).to be_counted_towards_rollover
  end

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

  context 'manually settled lost bet' do
    let(:settlement_status) { Bet::LOST }
    let(:bet) { manually_settled_bet }
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

  context 'track settlement details' do
    let(:bet) { settled_bet }
    let!(:entry) { placement_entry }

    before { subject }

    it 'doesnt change bet_settlement_status_achieved_at' do
      expect(bet.reload.bet_settlement_status_achieved_at).to be_truthy
    end

    it 'sets current user as an initiator' do
      expect(bet.entry_requests.last.initiator).to eq(user)
    end
  end

  context 'entry balance calculation' do
    let(:bet) { settled_bet }
    let(:bet_leg_odd) {}
    let!(:bet_leg) { create(:bet_leg, :won, bet: bet) }
    let(:bonus) { customer_bonus }
    let!(:entry) { placement_entry }
    let(:ratio) do
      RatioCalculator.call(
        real_money_amount: placement_entry.real_money_amount,
        bonus_amount: placement_entry.bonus_amount
      )
    end
    let(:win_amount) do
      bet.amount * bet.odd_value
    end
    let(:real_money_win_amount) do
      win_amount.round(bet.currency.scale) * ratio
    end
    let(:bonus_win_amount) do
      win_amount.round(bet.currency.scale) -
        real_money_win_amount.round(bet.currency.scale)
    end

    CustomerBonus::DISMISSED_STATUSES.each do |status|
      context "won bet and #{status} bonus" do
        let(:bonus_status) { status }
        let!(:total_confiscated_amount) do
          bonus.total_confiscated_amount
        end
        let(:confiscated_amount) do
          total_confiscated_amount + bonus_win_amount
        end

        before { subject }

        it 'subtracts winning bonus part from confiscated amount' do
          expect(bonus.reload.total_confiscated_amount)
            .to eq(confiscated_amount)
        end
      end
    end

    context 'won bet and completed bonus' do
      let(:bonus_status) { CustomerBonus::COMPLETED }
      let!(:total_converted_amount) { bonus.total_converted_amount }
      let(:converted_amount) do
        total_converted_amount + bonus_win_amount
      end
      let!(:real_money_balance) { wallet.real_money_balance }
      let(:expected_real_money) { real_money_balance + bet.winning.amount }

      before { subject }

      it 'adds winning bonus part to converted amount' do
        expect(bonus.reload.total_converted_amount).to eq(converted_amount)
      end

      it 'adds winning bonus part to real money' do
        expect(wallet.reload.real_money_balance).to eq(expected_real_money)
      end
    end
  end
end
