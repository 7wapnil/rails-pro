# frozen_string_literal: true

describe EntryRequests::Factories::BetPlacement do
  subject { described_class.call(bet: bet, initiator: impersonated_by) }

  let(:bet) do
    create(:bet, customer: wallet.customer,
                 currency: currency,
                 customer_bonus: customer_bonus,
                 amount: 100,
                 bet_legs: [bet_leg])
  end

  let(:impersonated_by) { create(:customer) }
  let!(:wallet) do
    create(:wallet, :brick, currency: currency,
                            real_money_balance: 10, bonus_balance: 10)
  end
  let(:currency) { create(:currency) }
  let(:customer_bonus) { create(:customer_bonus) }
  let(:bet_leg) { create(:bet_leg, market: market) }
  let(:market) { create(:event, :with_market, :upcoming).markets.sample }

  let(:bet_attributes) do
    {
      amount: -bet.amount,
      currency: bet.currency,
      kind: EntryRequest::BET,
      mode: EntryRequest::INTERNAL,
      initiator: impersonated_by,
      customer: bet.customer,
      origin: bet
    }
  end

  let!(:prematch_producer) { create(:prematch_producer) }
  let!(:live_producer) { create(:liveodds_producer) }

  before do
    prematch_producer.healthy!
    create(
      :entry_currency_rule,
      currency: currency,
      kind: EntryRequest::BET,
      max_amount: 0,
      min_amount: -100
    )
    wallet.update(real_money_balance: bet.amount * 2, bonus_balance: 0)
  end

  it 'creates entry request' do
    expect { subject }.to change(EntryRequest, :count).by(1)
  end

  it 'creates entry request from bet with valid attributes' do
    expect(subject).to have_attributes(bet_attributes)
  end

  context 'with impersonated person' do
    let(:message) do
      "Bet placed - #{bet.amount} #{currency} for #{bet.customer} " \
      "by #{impersonated_by}"
    end

    it 'mentions him in comment' do
      expect(subject.comment).to eq(message)
    end
  end

  context 'without impersonated person' do
    let(:impersonated_by) {}
    let(:message) do
      "Bet placed - #{bet.amount} #{currency} for #{bet.customer}"
    end

    it 'does not mention him in comment' do
      expect(subject.comment).to eq(message)
    end

    it 'sets bet customer as initiator' do
      expect(subject.initiator).to eq(bet.customer)
    end
  end

  context 'with customer bonus not activated' do
    before do
      allow_any_instance_of(CustomerBonus)
        .to receive(:active?)
        .and_return(false)
    end

    it 'calls calculation service with default ratio' do
      expect(BalanceCalculations::Bet)
        .to receive(:call)
        .with(bet: bet)
        .and_call_original

      subject
    end
  end

  context 'if wallet not found' do
    before { wallet.update(customer: create(:customer)) }

    it 'does not create new wallet' do
      expect { subject }.not_to change(Wallet, :count)
    end
  end
end
