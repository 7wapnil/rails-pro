# frozen_string_literal: true

describe Bets::RollbackSettlement do
  subject { described_class.call(bet: bet) }

  let(:bet) { create(:bet, :settled, :won) }
  let!(:customer_bonus) do
    create(:customer_bonus, bets: [bet], customer: bet.customer)
  end
  let(:wallet) do
    create(:wallet, customer: bet.customer, currency: bet.currency)
  end
  let!(:balance) do
    create(:balance, :real_money, amount: 10_000, wallet: wallet)
  end

  let(:rollback_entry) { Entry.rollback.find_by(origin: bet) }

  include_context 'base_currency'

  before do
    allow(CustomerBonuses::RollbackBonusRolloverService).to receive(:call)
  end

  context 'on won bet' do
    let!(:win_entry) { create(:entry, :win, origin: bet, amount: bet.amount) }

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
        allow(bet).to receive(:update!).and_raise(StandardError, 'error')
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
    let(:bet) { create(:bet, :settled, :lost) }

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
    let(:bet) { create(:bet, :settled, :voided) }
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

    it 'calls bonuses rollover' do
      expect(CustomerBonuses::RollbackBonusRolloverService).to receive(:call)
      subject
    end
  end

  context 'on pending manual settlement bet' do
    let(:bet) { create(:bet, :pending_manual_settlement) }

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
    let(:bet) { create(:bet, :rejected) }

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
      expect { subject }
        .to raise_error('Bet has not been sent to settlement yet')
    end

    it 'does not call bonuses rollover' do
      expect(CustomerBonuses::RollbackBonusRolloverService)
        .not_to receive(:call)
      subject
    rescue StandardError
    end
  end
end
