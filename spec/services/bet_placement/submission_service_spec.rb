describe BetPlacement::SubmissionService do
  subject(:submission_service) { described_class.new(bet) }

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

  let!(:bet) do
    create(
      :bet,
      customer: wallet.customer,
      currency: currency,
      amount: 100,
      market: create(:event_with_market, :upcoming).markets.sample
    )
  end

  let(:bet_request) { submission_service.send(:entry_request) }
  let(:bet_attributes) do
    {
      amount: -bet.amount,
      currency: bet.currency,
      kind: EntryRequest::BET,
      mode: EntryRequest::SPORTS_TICKET,
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

  it_behaves_like 'callable service'

  describe '.call' do
    context 'with any wallet amount' do
      it 'creates an entry request from bet' do
        expect(bet_request).to be_an EntryRequest

        expect(bet_request).to have_attributes(bet_attributes)
      end

      it 'calls WalletEntry::Service with entry request' do
        expect(WalletEntry::AuthorizationService)
          .to receive(:call).with(bet_request)
        subject.call
      end
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

        expect(bet.status)
          .to eq StateMachines::BetStateMachine::SENT_TO_EXTERNAL_VALIDATION
        expect(bet.message).to be_nil
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

        expect(bet.status).to eq StateMachines::BetStateMachine::FAILED
        expect(bet.message).to be_a String
      end
    end

    context 'with failure' do
      let(:error_message) { Faker::Lorem.sentence }

      it 'call bet register_failure' do
        allow(subject).to receive(:amount_calculations).and_raise(StandardError,
                                                                  error_message)

        expect(bet).to receive(:register_failure).with(error_message)

        expect { subject.call }.to raise_error(StandardError)
      end
    end
  end
end
