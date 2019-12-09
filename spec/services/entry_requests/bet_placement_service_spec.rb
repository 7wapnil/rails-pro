# frozen_string_literal: true

describe EntryRequests::BetPlacementService do
  subject(:submission_service) do
    described_class.new(entry_request: entry_request)
  end

  let!(:currency) { create(:currency) }
  let!(:wallet) do
    create(:wallet, :brick, currency: currency,
                            real_money_balance: 200,
                            bonus_balance: 0)
  end

  let(:market) { create(:event, :with_market, :upcoming).markets.sample }
  let(:odd) { create(:odd, :active, market: market) }
  let!(:bet) do
    create(:bet, customer: wallet.customer,
                 currency: currency,
                 odd: odd,
                 amount: 100)
  end
  let(:entry_request) { EntryRequests::Factories::BetPlacement.call(bet: bet) }

  let(:bet_request) { submission_service.send(:entry_request) }
  let(:bet_attributes) do
    {
      amount: -bet.amount,
      currency: bet.currency,
      kind: EntryRequest::BET,
      mode: EntryRequest::INTERNAL,
      initiator: bet.customer,
      customer: bet.customer,
      origin: bet
    }
  end

  let!(:prematch_producer) { create(:prematch_producer) }
  let!(:live_producer) { create(:liveodds_producer) }

  before do
    create(:currency, :primary)

    allow(WebSocket::Client.instance).to receive(:trigger_bet_update)
    allow_any_instance_of(Mts::ValidationMessagePublisherWorker)
      .to receive(:perform)

    create(:entry_currency_rule, currency: currency,
                                 kind: EntryRequest::BET,
                                 max_amount: 0,
                                 min_amount: -100)
  end

  context 'with valid betting limit' do
    before do
      create(:betting_limit, title: nil,
                             customer: bet.customer,
                             live_bet_delay: 10,
                             user_max_bet: bet.amount + 1,
                             max_loss: bet.amount + 1,
                             max_win: bet.amount * bet.odd_value + 1,
                             user_stake_factor: 1,
                             live_stake_factor: 1)
    end

    it 'updates bet status as valid' do
      subject.call

      expect(bet)
        .to have_attributes(
          notification_message: nil,
          notification_code: nil,
          status: StateMachines::BetStateMachine::SENT_TO_EXTERNAL_VALIDATION
        )
    end
  end

  context 'with disconnected provider' do
    let!(:prematch_producer) { create(:prematch_producer, :unsubscribed) }

    it 'fails when provider disconnected' do
      subject.call

      expect(bet)
        .to have_attributes(
          notification_message: I18n.t('errors.messages.provider_disconnected'),
          notification_code: Bets::Notification::INTERNAL_VALIDATION_ERROR,
          status: StateMachines::BetStateMachine::FAILED
        )
    end
  end

  context 'with inactive odd' do
    let(:odd) { create(:odd) }

    before { subject.call }

    it 'bet fails' do
      expect(bet).to have_attributes(
        notification_message: I18n.t('errors.messages.bet_odd_inactive'),
        notification_code: Bets::Notification::INTERNAL_VALIDATION_ERROR,
        status: StateMachines::BetStateMachine::FAILED
      )
    end
  end

  context 'with invalid betting limit' do
    before do
      create(:betting_limit, title: nil,
                             customer: bet.customer,
                             live_bet_delay: 10,
                             user_max_bet: bet.amount - 1,
                             max_loss: bet.amount - 1,
                             max_win: bet.amount * bet.odd_value - 1,
                             user_stake_factor: 2,
                             live_stake_factor: 2)
    end

    it 'updates bet status and message on failure' do
      subject.call

      expect(bet)
        .to have_attributes(
          notification_message: I18n.t('errors.messages.betting_limits'),
          notification_code: Bets::Notification::INTERNAL_VALIDATION_ERROR,
          status: StateMachines::BetStateMachine::FAILED
        )
    end
  end

  context 'with suspended market' do
    before do
      market.update!(status: Market::SUSPENDED)
      subject.call
    end

    it 'fails when market suspended' do
      expect(bet).to have_attributes(
        notification_message: I18n.t('errors.messages.market_inactive'),
        notification_code: Bets::Notification::INTERNAL_VALIDATION_ERROR,
        status: StateMachines::BetStateMachine::FAILED
      )
    end
  end

  context 'with failure' do
    let(:error_message) { Faker::Lorem.sentence }

    before do
      allow(bet).to receive(:register_failure).with(error_message)

      allow(BalanceCalculations::Bet)
        .to receive(:call).and_raise(StandardError, error_message)
    end

    it 'call bet register_failure' do
      expect { subject.call }.to raise_error(StandardError, error_message)
    end
  end

  context 'with zero amount for entry request' do
    let(:error_message) { I18n.t('errors.messages.real_money_blank_amount') }
    let(:subject_result) { subject.call }

    before { entry_request.amount = 0 }

    context 'on failure' do
      include_context 'asynchronous to synchronous'

      it 'notifies betslip' do
        expect(WebSocket::Client.instance).to receive(:trigger_bet_update)
        subject_result
      end
    end

    it 'service does not proceed after internal validation' do
      expect(bet).not_to receive(:finish_internal_validation_successfully!)
      subject_result
    end

    it 'bet is failed' do
      subject_result
      expect(bet).to have_attributes(
        notification_message: error_message,
        notification_code: Bets::Notification::INTERNAL_VALIDATION_ERROR,
        status: StateMachines::BetStateMachine::FAILED
      )
    end

    it 'entry request is failed' do
      subject_result
      expect(entry_request).to have_attributes(
        status: EntryRequest::FAILED,
        result: { 'message' => error_message }
      )
    end
  end

  context 'with failed entry request' do
    let(:error_message) do
      I18n.t('errors.messages.entry_request_failed')
    end

    before { entry_request.failed! }

    context 'on failure' do
      include_context 'asynchronous to synchronous'

      it 'notifies betslip' do
        expect(WebSocket::Client.instance).to receive(:trigger_bet_update)
        subject.call
      end
    end

    it 'service does not proceed after internal validation' do
      expect(bet).not_to receive(:finish_internal_validation_successfully!)
      subject.call
    end

    it 'does not proceed updating wallets' do
      subject.call
      expect(WalletEntry::AuthorizationService).not_to receive(:call)
    end

    it 'fails bet' do
      subject.call
      expect(bet).to have_attributes(
        notification_message: error_message,
        notification_code: Bets::Notification::INTERNAL_VALIDATION_ERROR,
        status: StateMachines::BetStateMachine::FAILED
      )
    end
  end
end
