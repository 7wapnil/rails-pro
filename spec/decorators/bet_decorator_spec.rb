# frozen_string_literal: true

describe BetDecorator, type: :decorator do
  subject { bet.decorate }

  let(:bet) { build(:bet) }
  let!(:primary_currency) { create(:currency, :primary) }

  describe '#display_status' do
    pending_statuses = StateMachines::BetStateMachine::PENDING_STATUSES_MASK
    pending_statuses.each do |status|
      context "on #{status} status" do
        let(:bet) { build(:bet, status: status) }

        it 'returns PENDING status' do
          expect(subject.display_status).to eq(described_class::PENDING)
        end
      end
    end

    cancelled_statuses = StateMachines::BetStateMachine::CANCELLED_STATUSES_MASK
    cancelled_statuses.each do |status|
      context "on #{status} status" do
        let(:bet) { build(:bet, status: status) }

        it 'returns CANCELLED status' do
          expect(subject.display_status).to eq(described_class::CANCELLED)
        end
      end
    end

    settled_statuses = StateMachines::BetStateMachine::SETTLED_STATUSES_MASK
    settled_statuses.each do |status|
      context "on #{status} status" do
        let(:settlement_status) do
          StateMachines::BetStateMachine::BET_SETTLEMENT_STATUSES.values.sample
        end
        let(:bet) do
          build(:bet, status: status,
                      settlement_status: settlement_status)
        end

        it 'returns settlement status' do
          expect(subject.display_status).to eq(settlement_status)
        end
      end
    end

    common_statuses = Bet.statuses.values -
                      pending_statuses -
                      cancelled_statuses -
                      settled_statuses
    common_statuses.each do |status|
      context "on #{status} status" do
        let(:bet) { build(:bet, status: status) }

        it 'returns original status' do
          expect(subject.display_status).to eq(bet.status)
        end
      end
    end
  end

  describe '#amount' do
    it 'returns common value' do
      expect(subject.amount).to eq(bet.amount)
    end

    it 'returns humanized value' do
      decorated_value = helpers.number_with_precision(
        bet.amount,
        precision: bet.currency.scale
      )

      expect(subject.amount(human: true)).to eq(decorated_value)
    end
  end

  describe '#base_currency_amount' do
    it 'returns common value' do
      expect(subject.base_currency_amount).to eq(bet.base_currency_amount)
    end

    it 'returns humanized value' do
      decorated_value = helpers.number_with_precision(
        bet.base_currency_amount,
        precision: Currency.primary.scale
      )

      expect(subject.base_currency_amount(human: true)).to eq(decorated_value)
    end
  end

  describe '#created_at' do
    let(:bet) { create(:bet) }

    it 'returns common value' do
      expect(subject.created_at).to eq(bet.created_at)
    end

    it 'returns humanized value' do
      expect(subject.created_at(human: true))
        .to eq(I18n.l(bet.created_at, format: :long))
    end
  end

  describe '#human_notification_message' do
    it 'returns nothing' do
      expect(subject.human_notification_message).to be_nil
    end

    context 'with notification' do
      let(:bet) { build(:bet, :with_notification) }

      it 'returns notification message' do
        expect(subject.human_notification_message)
          .to eq(I18n.t("bets.notifications.#{bet.notification_code}",
                        default: bet.notification_message))
      end
    end

    context 'with unknown notification' do
      let(:bet) { build(:bet, notification_code: 'hello') }

      it 'returns nothing' do
        expect(subject.human_notification_message).to be_nil
      end
    end
  end
end
