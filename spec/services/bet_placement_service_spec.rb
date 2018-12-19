describe BetPlacement::SubmissionService do
  before do
    allow_any_instance_of(Mts::ValidationMessagePublisherWorker)
      .to receive(:perform)
    ApplicationState.instance.live_connected = true
    ApplicationState.instance.pre_live_connected = true
  end
  let!(:currency) { create(:currency) }
  let!(:bet_rule) do
    create(
      :entry_currency_rule,
      currency: currency,
      kind: EntryRequest::BET,
      max_amount: 0,
      min_amount: -100
    )
  end
  let!(:wallet) do
    create(
      :wallet,
      :brick,
      currency: currency
    )
  end
  let!(:bet) do
    create(
      :bet,
      customer: wallet.customer,
      currency: currency,
      amount: 100
    )
  end
  let!(:balance) do
    create(:balance, wallet: wallet, amount: bet.amount * 2)
  end

  subject { described_class.new(bet) }

  let(:bet_request) { subject.send(:entry_request) }

  it_behaves_like 'callable service'

  describe '.call' do
    context 'with any wallet amount' do
      it 'creates an entry request from bet' do
        expect(bet_request).to be_an EntryRequest

        expect(bet_request)
          .to have_attributes(
            amount: -bet.amount,
            currency: bet.currency,
            kind: 'bet',
            mode: 'sports_ticket',
            initiator: bet.customer,
            customer: bet.customer,
            origin: bet
          )
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

        expect(bet.status).to eq 'sent_to_external_validation'
        expect(bet.message).to be_nil
      end
    end

    context 'with disconnected provider' do
      it 'updates bet status as valid' do
        subject.call

        expect(bet.status).to eq 'sent_to_external_validation'
        expect(bet.message).to be_nil
      end

      it 'updates bet status and error message' do
        ApplicationState.instance.live_connected = false
        ApplicationState.instance.pre_live_connected = false

        subject.call

        expect(bet.status).to eq 'failed'
        expect(bet.message).to be_a String
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

        expect(bet.status).to eq 'failed'
        expect(bet.message).to be_a String
      end
    end

    context 'with empty real amount' do
      it 'raise error when real amount is nil' do
        calculations = { real_money: nil, bonus: 10 }
        allow(subject).to receive(:amount_calculations).and_return(calculations)

        expect { subject.call }.to raise_error(ArgumentError)
      end

      it 'raise error when real amount is 0' do
        calculations = { real_money: 0, bonus: 10 }
        allow(subject).to receive(:amount_calculations).and_return(calculations)

        expect { subject.call }.to raise_error(ArgumentError)
      end
    end
  end
end
