# frozen_string_literal: true

describe Bets::RollbackSettlement do
  subject { described_class.call(bet_leg: bet_leg) }

  let(:bet) { create(:bet, :settled, :won, :with_bet_leg) }
  let(:bet_leg) { bet.bet_legs.first }
  let!(:customer_bonus) do
    create(:customer_bonus, bets: [bet], customer: bet.customer)
  end
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
          I18n.t('errors.messages.bonus_for_wrong_customer')
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
end
