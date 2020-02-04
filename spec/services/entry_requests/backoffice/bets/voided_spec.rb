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
  let(:bet) { placed_bet }

  context 'bonus rollover' do
    let(:counted_towards_rollover) { true }

    before { placement_entry }

    it 'rolbacks bonus rollover' do
      subject
      expect(bet.reload).not_to be_counted_towards_rollover
    end
  end

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

  context 'entry balance calculation' do
    let(:bet) { placed_bet }
    let(:bonus) { customer_bonus }
    let!(:entry) { placement_entry }

    CustomerBonus::DISMISSED_STATUSES.each do |status|
      context "voided bet and #{status} bonus" do
        let(:bonus_status) { status }
        let!(:total_confiscated_amount) do
          bonus.total_confiscated_amount
        end
        let(:confiscated_amount) do
          total_confiscated_amount + placement_entry.bonus_amount.abs
        end

        before { subject }

        it 'subtracts placed bonus part from confiscated amount' do
          expect(bonus.reload.total_confiscated_amount)
            .to eq(confiscated_amount)
        end
      end
    end

    context 'voided bet and completed bonus' do
      let(:bonus_status) { CustomerBonus::COMPLETED }
      let!(:total_converted_amount) { bonus.total_converted_amount }
      let(:converted_amount) do
        total_converted_amount + placement_entry.bonus_amount.abs
      end
      let!(:real_money_balance) { wallet.real_money_balance }
      let(:expected_real_money) do
        real_money_balance + bet.placement_entry.amount.abs
      end

      before { subject }

      it 'adds placed bonus part to converted amount' do
        expect(bonus.reload.total_converted_amount).to eq(converted_amount)
      end

      it 'adds placed bonus part to real money' do
        expect(wallet.reload.real_money_balance).to eq(expected_real_money)
      end
    end
  end
end
