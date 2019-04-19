# frozen_string_literal: true

describe EntryRequests::BetPlacementService do
  subject(:submission_service) do
    described_class.new(entry_request: entry_request)
  end

  let!(:currency) { create(:currency) }
  let!(:wallet) do
    create(
      :wallet,
      :brick,
      currency: currency
    )
  end

  let(:bonus_balance) { create(:balance, :bonus, wallet: wallet) }
  let(:real_money_balance) { create(:balance, wallet: wallet) }

  let(:odd) { create(:odd, :active) }
  let!(:bet) do
    create(
      :bet,
      customer: wallet.customer,
      currency: currency,
      odd: odd,
      amount: 100,
      market: create(:event, :with_market, :upcoming).markets.sample
    )
  end
  let(:entry_request) { EntryRequests::Factories::BetPlacement.call(bet: bet) }

  let(:bet_request) { submission_service.send(:entry_request) }
  let(:bet_attributes) do
    {
      amount: -bet.amount,
      currency: bet.currency,
      kind: EntryRequest::BET,
      mode: EntryRequest::SYSTEM,
      initiator: bet.customer,
      customer: bet.customer,
      origin: bet
    }
  end

  let!(:prematch_producer) { create(:prematch_producer) }
  let!(:live_producer) { create(:liveodds_producer) }

  before do
    allow_any_instance_of(Mts::ValidationMessagePublisherWorker)
      .to receive(:perform)
    prematch_producer.healthy!
    create(
      :entry_currency_rule,
      currency: currency,
      kind: EntryRequest::BET,
      max_amount: 0,
      min_amount: -100
    )
    create(:balance, wallet: wallet, amount: bet.amount * 2)
    create(:balance, :bonus, wallet: wallet, amount: 0)
  end

  context 'with valid betting limit' do
    before do
      create(
        :betting_limit,
        title: nil,
        customer: bet.customer,
        live_bet_delay: 10,
        user_max_bet: bet.amount + 1,
        max_loss: bet.amount + 1,
        max_win: bet.amount * bet.odd_value + 1,
        user_stake_factor: 1,
        live_stake_factor: 1
      )
    end

    it 'updates bet status as valid' do
      subject.call

      expect(bet)
        .to have_attributes(
          status: StateMachines::BetStateMachine::SENT_TO_EXTERNAL_VALIDATION,
          message: nil
        )
    end

    it 'emits bet update websocket event' do
      expect(WebSocket::Client.instance)
        .to receive(:trigger_bet_update)

      subject.call
    end
  end

  context 'with disconnected provider' do
    it 'fails when provider disconnected' do
      live_producer.healthy!
      prematch_producer.unsubscribed!

      subject.call

      expect(bet)
        .to have_attributes(
          message: I18n.t('errors.messages.provider_disconnected'),
          status: StateMachines::BetStateMachine::FAILED
        )
    end
  end

  context 'with inactive odd' do
    let(:odd) { create(:odd) }

    before { subject.call }

    it 'bet fails' do
      expect(bet).to have_attributes(
        message: I18n.t('errors.messages.bet_odd_inactive'),
        status: StateMachines::BetStateMachine::FAILED
      )
    end
  end

  context 'with invalid betting limit' do
    before do
      create(
        :betting_limit,
        title: nil,
        customer: bet.customer,
        live_bet_delay: 10,
        user_max_bet: bet.amount - 1,
        max_loss: bet.amount - 1,
        max_win: bet.amount * bet.odd_value - 1,
        user_stake_factor: 2,
        live_stake_factor: 2
      )
    end

    it 'updates bet status and message on failure' do
      subject.call

      expect(bet)
        .to have_attributes(
          status: StateMachines::BetStateMachine::FAILED,
          message: instance_of(String)
        )
    end
  end

  context 'with suspended market' do
    before do
      bet.market.update!(status: Market::SUSPENDED)
      subject.call
    end

    it 'fails when market suspended' do
      expect(bet).to have_attributes(
        message: I18n.t('errors.messages.market_suspended'),
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

    before do
      entry_request.amount = 0
      subject_result
    end

    it 'service returns nothing' do
      expect(subject_result).to be_nil
    end

    it 'bet is failed' do
      expect(bet).to have_attributes(
        status: StateMachines::BetStateMachine::FAILED,
        message: error_message
      )
    end

    it 'entry request is failed' do
      expect(entry_request).to have_attributes(
        status: EntryRequest::FAILED,
        result: { 'message' => error_message }
      )
    end
  end

  context 'with failed entry request' do
    let(:error_message) do
      I18n.t('errors.messages.entry_request_failed', bet_id: bet.id)
    end

    before { entry_request.failed! }

    it 'returns falsey result' do
      expect(subject.call).to be_falsey
    end

    it 'does not proceed' do
      subject.call
      expect(WalletEntry::AuthorizationService).not_to receive(:call)
    end

    it 'fails bet' do
      subject.call
      expect(bet).to have_attributes(
        status: StateMachines::BetStateMachine::FAILED,
        message: error_message
      )
    end
  end
end
