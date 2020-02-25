# frozen_string_literal: true

describe Bets::RollbackSettlement do
  subject { described_class.call(bet_leg: bet_leg) }

  let(:bet) { create(:bet, :settled, :won, :with_bet_leg) }
  let(:bet_leg) { bet.bet_legs.first }
  let!(:customer_bonus) do
    create(:customer_bonus, bets: [bet],
                            customer: bet.customer,
                            status: bonus_status)
  end
  let(:bonus_status) { CustomerBonus::ACTIVE }
  let(:initial_value) { 10_000 }
  let!(:wallet) do
    create(:wallet, customer: bet.customer,
                    currency: bet.currency,
                    real_money_balance: initial_value,
                    bonus_balance: initial_value)
  end

  let(:rollback_entry) { Entry.rollback.find_by(origin: bet) }

  include_context 'base_currency'

  before do
    allow(CustomerBonuses::RollbackBonusRolloverService).to receive(:call)
  end

  context 'on won bet' do
    let!(:win_entry) do
      create(:entry, :win, :with_balance_entries,
             origin: bet,
             amount: bet.amount)
    end

    it 'is reverted' do
      subject
      expect(bet.reload).to have_attributes(
        void_factor: nil,
        status: StateMachines::BetStateMachine::ACCEPTED,
        settlement_status: nil
      )
    end

    it 'creates rollback entry' do
      expect { subject }.to change(Entry, :count).by(1)
    end

    it 'assigns valid attributes to rollback entry' do
      subject
      expect(rollback_entry).to have_attributes(
        amount: -win_entry.amount,
        wallet: wallet
      )
    end

    it 'calls bonuses rollover' do
      expect(CustomerBonuses::RollbackBonusRolloverService).to receive(:call)
      subject
    end

    it 'updates real money balance' do
      subject
      expect(wallet.reload.real_money_balance)
        .to eq(initial_value - win_entry.real_money_amount)
    end

    it 'updates bonus balance' do
      subject
      expect(wallet.reload.bonus_balance)
        .to eq(initial_value - win_entry.bonus_amount)
    end

    context 'when there is no bonus assigned' do
      let(:customer_bonus) {}

      before { subject }

      it 'does not call bonuses rollover' do
        expect(CustomerBonuses::RollbackBonusRolloverService)
          .not_to have_received(:call)
      end
    end

    context 'when bonus has another customer assigned' do
      let(:customer_bonus) { create(:customer_bonus, bets: [bet]) }

      it 'raises an error' do
        expect { subject }.to raise_error(
          I18n.t('internal.errors.messages.bonus_for_wrong_customer')
        )
      end

      it 'does not create entry' do
        expect do
          subject
        rescue StandardError
        end.not_to change(Entry, :count)
      end

      it 'does not revert bet' do
        subject
      rescue StandardError
        expect(bet.reload).to have_attributes(
          status: StateMachines::BetStateMachine::SETTLED,
          settlement_status: StateMachines::BetStateMachine::WON
        )
      end
    end

    context 'when error appears on bet updating' do
      before do
        allow(bet)
          .to receive(:rollback_settlement!)
          .and_raise(StandardError, 'error')
      end

      it 'raises an error' do
        expect { subject }.to raise_error(StandardError, 'error')
      end

      it 'does not create entry' do
        expect do
          subject
        rescue StandardError
        end.not_to change(Entry, :count)
      end
    end
  end

  context 'on lost bet' do
    let(:bet) { create(:bet, :settled, :lost, :with_bet_leg) }

    it 'is reverted' do
      subject
      expect(bet.reload).to have_attributes(
        void_factor: nil,
        status: StateMachines::BetStateMachine::ACCEPTED,
        settlement_status: nil
      )
    end

    it 'does not create rollback entry' do
      expect { subject }.not_to change(Entry, :count)
    end

    it 'calls bonuses rollover' do
      expect(CustomerBonuses::RollbackBonusRolloverService).to receive(:call)
      subject
    end
  end

  context 'on voided bet' do
    let(:bet) { create(:bet, :settled, :voided, :with_bet_leg) }
    let!(:refund_entry) do
      create(:entry, :refund, origin: bet, amount: bet.amount)
    end

    it 'is reverted' do
      subject
      expect(bet.reload).to have_attributes(
        void_factor: nil,
        status: StateMachines::BetStateMachine::ACCEPTED,
        settlement_status: nil
      )
    end

    it 'creates rollback entry' do
      expect { subject }.to change(Entry, :count).by(1)
    end

    it 'assigns valid attributes to rollback entry' do
      subject
      expect(rollback_entry).to have_attributes(
        amount: -refund_entry.amount,
        wallet: wallet
      )
    end

    it 'does not call bonuses rollover' do
      expect(CustomerBonuses::RollbackBonusRolloverService)
        .not_to receive(:call)
      subject
    end
  end

  context 'on pending manual settlement bet' do
    let(:bet) { create(:bet, :pending_manual_settlement, :with_bet_leg) }

    it 'is reverted' do
      subject
      expect(bet.reload).to have_attributes(
        void_factor: nil,
        status: StateMachines::BetStateMachine::ACCEPTED,
        settlement_status: nil
      )
    end

    it 'does not create rollback entry' do
      expect { subject }.not_to change(Entry, :count)
    end

    it 'does not call bonuses rollover' do
      expect(CustomerBonuses::RollbackBonusRolloverService)
        .not_to receive(:call)
      subject
    end
  end

  context 'on invalid bet' do
    let(:bet) { create(:bet, :rejected, :with_bet_leg) }

    it 'is not reverted' do
      subject
    rescue StandardError
      expect(bet.reload.status).to eq(StateMachines::BetStateMachine::REJECTED)
    end

    it 'does not create rollback entry' do
      expect do
        subject
      rescue StandardError
      end.not_to change(Entry, :count)
    end

    it 'raises an error' do
      expect { subject }.to raise_error(
        'Bet has not been sent to settlement yet/was not accepted'
      )
    end

    it 'does not call bonuses rollover' do
      expect(CustomerBonuses::RollbackBonusRolloverService)
        .not_to receive(:call)
      subject
    rescue StandardError
    end
  end

  context 'on pending manual settlement when another lost bet leg' do
    let(:bet) do
      create(:bet, :lost, :pending_manual_settlement,
             :with_bet_leg, :combo_bets)
    end
    let(:bet_leg) { bet.bet_legs.first }

    before do
      create(:bet_leg, :lost, bet: bet)
    end

    it 'approves bet lost' do
      subject
      expect(bet.reload).to have_attributes(
        void_factor: nil,
        status: StateMachines::BetStateMachine::SETTLED,
        settlement_status: Bet::LOST
      )
    end

    it 'cleans bet leg statuses' do
      subject
      expect(bet_leg.reload).to have_attributes(status: nil,
                                                settlement_status: nil)
    end

    it 'does not create rollback entry' do
      expect { subject }.not_to change(Entry, :count)
    end

    it 'does not call bonuses rollover' do
      expect(CustomerBonuses::RollbackBonusRolloverService)
        .not_to receive(:call)
      subject
    end
  end

  context 'on lost bet leg when another lost bet leg' do
    let(:bet) { create(:bet, :lost, :settled, :with_bet_leg, :combo_bets) }
    let(:bet_leg) { bet.bet_legs.first }

    before do
      create(:bet_leg, :lost, bet: bet)
    end

    it 'keeps bet lost' do
      subject
      expect(bet.reload).to have_attributes(
        void_factor: nil,
        status: StateMachines::BetStateMachine::SETTLED,
        settlement_status: Bet::LOST
      )
    end

    it 'cleans bet leg statuses' do
      subject
      expect(bet_leg.reload).to have_attributes(status: nil,
                                                settlement_status: nil)
    end

    it 'does not create rollback entry' do
      expect { subject }.not_to change(Entry, :count)
    end

    it 'does not call bonuses rollover' do
      expect(CustomerBonuses::RollbackBonusRolloverService)
        .not_to receive(:call)
      subject
    end
  end

  context 'on multiple pending manual settlement for bet leg' do
    let(:bet) do
      create(:bet, :pending_manual_settlement, :combo_bets)
    end
    let(:bet_leg) { create(:bet_leg, :pending_manual_settlement, bet: bet) }

    before do
      create(:bet_leg, :pending_manual_settlement, bet: bet)
    end

    it 'keeps bet status' do
      subject
      expect(bet.reload).to have_attributes(
        status: StateMachines::BetStateMachine::PENDING_MANUAL_SETTLEMENT,
        settlement_status: nil
      )
    end

    it 'cleans bet leg statuses' do
      subject
      expect(bet_leg.reload).to have_attributes(status: nil,
                                                settlement_status: nil)
    end

    it 'does not create rollback entry' do
      expect { subject }.not_to change(Entry, :count)
    end

    it 'does not call bonuses rollover' do
      expect(CustomerBonuses::RollbackBonusRolloverService)
        .not_to receive(:call)
      subject
    end
  end

  context 'on lost bet leg and another bet leg on pending manual settlement' do
    let(:bet) do
      create(:bet, :lost, :pending_manual_settlement, :combo_bets)
    end
    let(:bet_leg) { create(:bet_leg, :lost, bet: bet) }

    before do
      create(:bet_leg, :pending_manual_settlement, bet: bet)
    end

    it 'rollback bet status to accepted' do
      subject
      expect(bet.reload).to have_attributes(
        status: StateMachines::BetStateMachine::PENDING_MANUAL_SETTLEMENT,
        settlement_status: nil
      )
    end

    it 'cleans bet leg statuses' do
      subject
      expect(bet_leg.reload).to have_attributes(status: nil,
                                                settlement_status: nil)
    end

    it 'does not create rollback entry' do
      expect { subject }.not_to change(Entry, :count)
    end

    it 'calls bonuses rollover' do
      expect(CustomerBonuses::RollbackBonusRolloverService).to receive(:call)
      subject
    end
  end

  context 'bonuses' do
    let(:bet_status) { Bet::SETTLED }
    let(:bet_settlement_status) { Bet::LOST }
    let(:bonus_status) { CustomerBonus::COMPLETED }
    let(:bet) do
      create(:bet, status: bet_status, settlement_status: bet_settlement_status)
    end
    let!(:bet_leg) do
      create(:bet_leg, bet: bet, settlement_status: bet_settlement_status)
    end
    let(:bonus) { bet.customer_bonus }

    CustomerBonus::USED_STATUSES.each do |status|
      context "lost bet and #{status} bonus" do
        let(:bonus_status) { status }

        before { subject }

        it 'does not change balance' do
          expect(wallet.amount).to eq(wallet.reload.amount)
        end
      end
    end

    CustomerBonus::DISMISSED_STATUSES.each do |status|
      context "won bet and #{status} bonus" do
        let(:bet_settlement_status) { Bet::WON }
        let(:bonus_status) { status }
        let!(:winning) do
          create(:entry, :win, :with_balance_entries, origin: bet,
                                                      wallet: wallet)
        end
        let!(:total_confiscated_amount) do
          bonus.total_confiscated_amount
        end
        let(:confiscated_amount) do
          total_confiscated_amount - bet.winning.bonus_amount
        end

        before { subject }

        it 'subtracts winning bonus part from confiscated amount' do
          expect(bonus.reload.total_confiscated_amount)
            .to eq(confiscated_amount)
        end
      end
    end

    context 'won bet and completed bonus' do
      let(:bet_settlement_status) { Bet::WON }
      let!(:winning) do
        create(:entry, :win, :with_balance_entries, origin: bet,
                                                    wallet: wallet)
      end
      let!(:total_converted_amount) { bonus.total_converted_amount }
      let(:converted_amount) do
        total_converted_amount - bet.winning.bonus_amount
      end
      let!(:real_money_balance) { wallet.real_money_balance }
      let(:expected_real_money) { real_money_balance - bet.winning.amount }

      before { subject }

      it 'subtracts winning bonus part from converted amount' do
        expect(bonus.reload.total_converted_amount).to eq(converted_amount)
      end

      it 'subtracts winning bonus part from real money' do
        expect(wallet.reload.real_money_balance).to eq(expected_real_money)
      end
    end
  end

  context 'non-balance bonus fields transition' do
    let(:bet_settlement_status) { Bet::WON }
    let(:bet) do
      create(:bet, :with_placement_entry, :settled,
             settlement_status: bet_settlement_status)
    end
    let!(:bet_leg) do
      create(:bet_leg, bet: bet, settlement_status: bet_settlement_status)
    end
    let!(:customer_bonus) do
      create(:customer_bonus, bets: [bet],
                              customer: bet.customer,
                              status: bonus_status,
                              **bonus_track_attributes)
    end
    let(:bonus_track_attributes) { {} }
    let(:bonus_status) { CustomerBonus::COMPLETED }
    let!(:winning) do
      create(:entry, :win, origin: bet,
                           wallet: wallet,
                           **affected_bonus_transition)
    end
    let(:bonus) { bet.customer_bonus }
    let(:affected_bonus_amount) { 10 }
    let(:default_affected_bonus_amount) { 100 }
    let(:affected_amount) do
      default_affected_bonus_amount - affected_bonus_amount
    end

    before { subject }

    context 'converted amount' do
      let(:bonus_track_attributes) do
        { total_converted_amount: default_affected_bonus_amount }
      end
      let(:affected_bonus_transition) do
        { converted_bonus_amount: affected_bonus_amount }
      end

      it 'counts converted amount to total' do
        expect(bonus.reload.total_converted_amount).to eq(affected_amount)
      end
    end

    context 'confiscated amount' do
      let(:bonus_status) { CustomerBonus::CANCELLED }
      let(:bonus_track_attributes) do
        { total_confiscated_amount: default_affected_bonus_amount }
      end
      let(:affected_bonus_transition) do
        { confiscated_bonus_amount: affected_bonus_amount }
      end

      it 'counts confiscated amount to total' do
        expect(bonus.reload.total_confiscated_amount).to eq(affected_amount)
      end
    end
  end
end
