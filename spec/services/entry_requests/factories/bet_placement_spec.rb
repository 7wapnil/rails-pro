# frozen_string_literal: true

describe EntryRequests::Factories::BetPlacement do
  subject { described_class.call(bet: bet, initiator: impersonated_by) }

  let(:bet) do
    create(:bet, customer: wallet.customer,
                 currency: currency,
                 customer_bonus: customer_bonus,
                 amount: 100,
                 market: market)
  end

  let(:impersonated_by) { create(:customer) }
  let(:wallet) { create(:wallet, :brick, currency: currency) }
  let(:currency) { create(:currency) }
  let(:customer_bonus) { create(:customer_bonus, :applied) }
  let(:market) { create(:event, :with_market, :upcoming).markets.sample }

  let(:bonus_balance) { create(:balance, :bonus, wallet: wallet) }
  let(:real_money_balance) { create(:balance, wallet: wallet) }

  let(:bet_attributes) do
    {
      amount: -bet.amount,
      currency: bet.currency,
      kind: EntryRequest::BET,
      mode: EntryRequest::SYSTEM,
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
    create(:balance, wallet: wallet, amount: bet.amount * 2)
    create(:balance, :bonus, wallet: wallet, amount: 0)
  end

  it 'creates entry request' do
    expect { subject }.to change(EntryRequest, :count).by(1)
  end

  it 'if creates balance entry request' do
    expect { subject }.to change(BalanceEntryRequest, :count).by(1)
  end

  it 'creates entry request from bet with valid attributes' do
    expect(subject).to have_attributes(bet_attributes)
  end

  context 'with impersonated person' do
    let(:message) do
      "Withdrawal #{bet.amount} #{currency} for #{bet.customer} " \
      "by #{impersonated_by}"
    end

    it 'mentions him in comment' do
      expect(subject.comment).to eq(message)
    end
  end

  context 'without impersonated person' do
    let(:impersonated_by) {}
    let(:message) do
      "Withdrawal #{bet.amount} #{currency} for #{bet.customer}"
    end

    it 'does not mention him in comment' do
      expect(subject.comment).to eq(message)
    end

    it 'sets bet customer as initiator' do
      expect(subject.initiator).to eq(bet.customer)
    end
  end

  context 'with customer bonus not applied' do
    before do
      allow_any_instance_of(CustomerBonus)
        .to receive(:applied?)
        .and_return(false)
    end

    it 'calls calculation service with default ratio' do
      expect(BalanceCalculations::BetWithBonus)
        .to receive(:call)
        .with(bet, 1.0)
        .and_call_original

      subject
    end
  end

  context 'if wallet not found' do
    before do
      allow_any_instance_of(Wallet)
        .to receive(:ratio_with_bonus)
        .and_return(0)

      wallet.update(customer: create(:customer))
    end

    it 'creates new wallet' do
      expect { subject }.to change(Wallet, :count).by(1)
    end
  end
end
