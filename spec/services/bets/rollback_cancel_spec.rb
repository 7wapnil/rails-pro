# frozen_string_literal: true

describe Bets::RollbackCancel do
  subject { described_class.call(bet_leg: bet_leg, bet: bet.reload) }

  let(:bet) do
    create(:bet, :won, :cancelled_by_system, :with_bonus,
           :with_placement_entry, :with_settled_bet_leg)
  end
  let(:bet_leg) do
    create(:bet_leg, :cancelled_by_system,
           bet: bet,
           settlement_status: bet_leg_settlement_status)
  end
  let(:customer_bonus) { bet.customer_bonus }
  let(:bet_leg_settlement_status) { BetLeg::WON }
  let!(:placement_rollback_entry) do
    create(:entry, origin: bet,
                   wallet: wallet,
                   kind: EntryKinds::SYSTEM_BET_CANCEL,
                   amount: -bet.placement_entry.amount)
  end
  let!(:winning_rollback_entry) do
    create(:entry, origin: bet,
                   wallet: wallet,
                   kind: EntryKinds::SYSTEM_BET_CANCEL,
                   amount: -bet.winning.amount)
  end
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
    context 'settled canceled bet' do
      let!(:expected_amount) do
        wallet.amount +
          bet.winning_rollback_entry.amount.abs -
          bet.placement_rollback_entry.amount.abs
      end

      it 'creates placement and winning entries' do
        expect(EntryRequests::ProcessingService).to receive(:call).twice
        subject
      end

      it 'settles bet' do
        subject
        expect(bet.reload).to be_settled
      end

      it 'wins bet' do
        subject
        expect(bet.reload).to be_won
      end

      it 'updates wallet balance' do
        subject
        expect(wallet.reload.amount).to eq(expected_amount)
      end
    end

    context 'accepted canceled unsettled bet' do
      let(:bet) { create(:bet, :cancelled_by_system, :with_placement_entry) }
      let(:bet_leg_settlement_status) { nil }
      let!(:winning_rollback_entry) {}
      let!(:expected_amount) do
        wallet.amount - bet.placement_rollback_entry.amount.abs
      end

      it 'creates placement entry' do
        expect(EntryRequests::ProcessingService).to receive(:call).once
        subject
      end

      it 'accepts bet' do
        subject
        expect(bet.reload).to be_accepted
      end

      it 'does not change bet settlement status' do
        subject
        expect(bet.reload.settlement_status).to be_nil
      end

      it 'updates wallet balance' do
        subject
        expect(wallet.reload.amount).to eq(expected_amount)
      end
    end
  end

  context 'combo-bets' do
    let(:bet_status) { Bet::ACCEPTED }
    let(:settlement_status) { nil }
    let(:bet) do
      traits = [bet_status.to_sym, :with_placement_entry,
                :with_bonus, settlement_status&.to_sym]
      create(:bet, *traits.compact, combo_bets: true)
    end

    context 'unsettled bet' do
      let!(:unsettled_bet_leg) { create(:bet_leg, bet: bet) }
      let!(:winning_rollback_entry) {}
      let!(:expected_amount) { wallet.amount }

      it 'does not process eny entries requests' do
        expect(EntryRequests::ProcessingService).not_to receive(:call)
        subject
      end

      it 'keeps bet status' do
        subject
        expect(bet.reload).to be_accepted
      end

      it 'rollbacks bet leg' do
        subject
        expect(bet_leg.reload).to be_won
      end

      it 'removes bet leg status' do
        subject
        expect(bet_leg.reload.status).to be_nil
      end

      it 'does not change wallet balance' do
        subject
        expect(wallet.reload.amount).to eq(expected_amount)
      end
    end

    context 'with lost bet leg and processing another bet leg' do
      let(:bet_status) { Bet::SETTLED }
      let(:settlement_status) { Bet::LOST }
      let!(:winning_rollback_entry) {}
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

      it 'rollbacks bet leg' do
        subject
        expect(bet_leg.reload.status).to be_nil
      end

      it 'keeps bet leg settlement status' do
        subject
        expect(bet_leg.reload).to be_won
      end

      it 'does not change wallet balance' do
        subject
        expect(wallet.reload.amount).to eq(expected_amount)
      end
    end

    context 'with won bet leg and processing canceled lost bet leg' do
      let(:bet_status) { Bet::SETTLED }
      let(:settlement_status) { Bet::WON }
      let(:bet_leg_settlement_status) { BetLeg::LOST }
      let!(:won_bet_leg) { create(:bet_leg, :won, bet: bet) }
      let!(:placement_entry) do
        create(:entry, origin: bet,
                       wallet: wallet,
                       kind: EntryKinds::BET,
                       amount: bet.placement_entry.amount)
      end
      let!(:winning_rollback_entry) { nil }
      let!(:expected_amount) { wallet.amount - bet.winning.amount.abs }

      before do
        create(:entry_currency_rule, currency: bet.currency,
                                     kind: EntryKinds::SYSTEM_BET_CANCEL,
                                     min_amount: -initial_value,
                                     max_amount: initial_value)
      end

      it 'processes entries requests once' do
        expect(EntryRequests::ProcessingService).to receive(:call).once
        subject
      end

      it 'keeps bet status' do
        subject
        expect(bet.reload).to be_settled
      end

      it 'loses bet' do
        subject
        expect(bet.reload).to be_lost
      end

      it 'loses bet leg' do
        subject
        expect(bet_leg.reload).to be_lost
      end

      it 'updates wallet balance' do
        subject
        expect(wallet.reload.amount).to eq(expected_amount)
      end
    end

    context 'with voided bet leg and processing canceled won bet leg' do
      let(:bet_status) { Bet::SETTLED }
      let(:settlement_status) { Bet::WON }
      let(:bet_leg_settlement_status) { BetLeg::WON }
      let!(:voided_bet_leg) { create(:bet_leg, :voided, bet: bet) }
      let!(:expected_amount) do
        wallet.amount +
          (bet.amount * bet_leg.odd_value).round(bet.currency.scale) -
          bet.placement_rollback_entry.amount
      end

      it 'processes entries requests twice' do
        expect(EntryRequests::ProcessingService).to receive(:call).twice
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

      it 'rollbacks bet leg status' do
        subject
        expect(bet_leg.reload.status).to be_nil
      end

      it 'updates wallet balance' do
        subject
        expect(wallet.reload.amount).to eq(expected_amount)
      end

      context 'when bonus was completed before rollback' do
        let(:winning_entry) { bet.reload_winning }
        let(:ratio) do
          RatioCalculator.call(
            real_money_amount: bet.placement_entry.real_money_amount,
            bonus_amount: bet.placement_entry.bonus_amount
          )
        end
        let(:winning_real_money) do
          (winning_entry.amount * ratio).round(bet.currency.scale)
        end
        let(:converted_amount) { winning_entry.amount - winning_real_money }

        before { customer_bonus&.completed! }

        it 'returns all money as real money' do
          subject
          expect(wallet.reload.real_money_balance).to eq(expected_amount)
        end

        it 'stores converted amount in entry' do
          subject
          expect(winning_entry.converted_bonus_amount).to eq(converted_amount)
        end
      end
    end

    context 'with voided bet leg and processing canceled lost bet leg' do
      let(:bet_status) { Bet::SETTLED }
      let(:settlement_status) { Bet::VOIDED }
      let!(:winning_rollback_entry) {}
      let(:bet_leg_settlement_status) { BetLeg::LOST }
      let!(:voided_bet_leg) { create(:bet_leg, :voided, bet: bet) }
      let!(:expected_amount) do
        wallet.amount - placement_rollback_entry.amount
      end

      it 'processes entries requests once' do
        expect(EntryRequests::ProcessingService).to receive(:call).once
        subject
      end

      it 'keeps bet status' do
        subject
        expect(bet.reload).to be_settled
      end

      it 'rollbacks bet leg status' do
        subject
        expect(bet_leg.reload.status).to be_nil
      end

      it 'loses bet' do
        subject
        expect(bet_leg.reload).to be_lost
      end

      it 'updates wallet balance' do
        subject
        expect(wallet.reload.amount).to eq(expected_amount)
      end
    end

    context 'with won bet leg and processing canceled another won bet leg' do
      let(:bet_status) { Bet::SETTLED }
      let(:settlement_status) { Bet::WON }
      let(:bet_leg_settlement_status) { BetLeg::WON }
      let!(:won_bet_leg) { create(:bet_leg, :won, bet: bet) }
      let!(:re_placement_entry) do
        create(:entry, origin: bet,
                       wallet: wallet,
                       kind: EntryKinds::BET,
                       amount: bet.placement_entry.amount)
      end
      let!(:re_winning_entry) do
        create(:entry, origin: bet,
                       wallet: wallet,
                       kind: EntryKinds::WIN,
                       amount: bet.win_amount)
      end
      let!(:expected_amount) do
        wallet.amount -
          re_winning_entry.amount +
          (bet.amount *
            won_bet_leg.odd_value *
            bet_leg.odd_value).round(bet.currency.scale)
      end

      before do
        bet.currency
           .entry_currency_rules
           .update_all(min_amount: -initial_value,
                       max_amount: initial_value)
      end

      it 'processes entries requests twice' do
        expect(EntryRequests::ProcessingService).to receive(:call).twice
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

      it 'rollbacks bet leg status' do
        subject
        expect(bet_leg.reload.status).to be_nil
      end

      it 'updates wallet balance' do
        subject
        expect(wallet.reload.amount).to eq(expected_amount)
      end
    end
  end

  context 'bonuses' do
    let(:bet_status) { Bet::ACCEPTED }
    let(:settlement_status) { nil }
    let(:bet) do
      traits = [bet_status.to_sym, :with_bonus,
                :with_placement_entry, settlement_status&.to_sym]
      create(:bet, *traits.compact, combo_bets: true,
                                    bonus_status: bonus_status)
    end
    let(:bonus_status) { CustomerBonus::COMPLETED }
    let(:bonus) { bet.customer_bonus }

    context 're-win' do
      let(:bet_status) { Bet::SETTLED }
      let(:settlement_status) { Bet::WON }
      let(:bet_leg_settlement_status) { BetLeg::WON }
      let!(:won_bet_leg) { create(:bet_leg, :won, bet: bet) }
      let(:placed_amount) { bet.placement_entry.amount }
      let!(:re_placement_entry) do
        create(:entry, :with_balance_entries, origin: bet,
                                              wallet: wallet,
                                              kind: EntryKinds::BET,
                                              amount: placed_amount)
      end
      let!(:re_winning_entry) do
        create(:entry, :with_balance_entries, origin: bet,
                                              wallet: wallet,
                                              kind: EntryKinds::WIN,
                                              amount: bet.win_amount)
      end
      let(:ratio) do
        RatioCalculator.call(
          real_money_amount: bet.placement_entry.real_money_amount,
          bonus_amount: bet.placement_entry.bonus_amount
        )
      end
      let(:win_amount) do
        bet.amount *
          won_bet_leg.odd_value *
          bet_leg.odd_value
      end
      let(:real_money_win_amount) do
        win_amount.round(bet.currency.scale) * ratio
      end
      let(:bonus_win_amount) do
        win_amount.round(bet.currency.scale) -
          real_money_win_amount.round(bet.currency.scale)
      end

      CustomerBonus::DISMISSED_STATUSES.each do |status|
        context "re-win bet when #{status} bonus" do
          let(:bonus_status) { status }
          let!(:total_confiscated_amount) do
            bonus.total_confiscated_amount
          end
          let(:confiscated_amount) do
            total_confiscated_amount -
              re_winning_entry.bonus_amount +
              bonus_win_amount
          end

          before do
            bet.currency.entry_currency_rules.delete_all

            subject
          end

          it 'subtracts(adds) winning bonus part from confiscated amount' do
            expect(bonus.reload.total_confiscated_amount)
              .to eq(confiscated_amount)
          end
        end
      end

      context 'won bet and completed bonus' do
        let!(:total_converted_amount) { bonus.total_converted_amount }
        let(:converted_amount) do
          total_converted_amount -
            re_winning_entry.bonus_amount +
            bonus_win_amount
        end

        before do
          bet.currency.entry_currency_rules.delete_all

          subject
        end

        it 'subtracts(adds) winning bonus part from converted amount' do
          expect(bonus.reload.total_converted_amount).to eq(converted_amount)
        end
      end
    end
  end
end
