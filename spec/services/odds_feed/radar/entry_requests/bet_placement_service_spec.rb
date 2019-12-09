# frozen_string_literal: true

describe EntryRequests::BetPlacementService do
  subject { described_class.call(entry_request: entry_request) }

  let(:bet) { create(:bet, :with_bet_leg) }
  let!(:currency) { create(:currency, :primary) }
  let(:rule) { create(:entry_currency_rule) }
  let!(:entry) { create(:entry, origin: bet) }
  let(:impersonated_by) { create(:customer) }
  let(:entry_request) do
    create(:entry_request, :succeeded,
           origin: bet,
           initiator: bet.customer,
           amount: bet.amount,
           currency: bet.currency,
           kind: EntryRequest::BET,
           mode: EntryRequest::INTERNAL)
  end

  let!(:live_producer) { create(:liveodds_producer) }
  let!(:prematch_producer) { create(:prematch_producer) }

  before do
    allow(WalletEntry::AuthorizationService)
      .to receive(:call)
      .with(entry_request)

    allow(EntryCurrencyRule).to receive(:find_by!).and_return(rule)

    allow_any_instance_of(RatioCalculator).to receive(:call).and_return(0.75)
  end

  it 'valid' do
    subject
    expect(bet).to be_sent_to_external_validation
  end

  context 'invalid' do
    let!(:bet_limit) do
      create(:betting_limit, customer: bet.customer,
                             title: nil,
                             user_max_bet: 0)
    end

    context 'on failed limits validation' do
      before { subject }

      it { expect(bet.reload).to be_failed }
    end

    context 'on live provider disconnected' do
      let!(:live_producer) { create(:liveodds_producer, :unsubscribed) }

      let(:event) { create(:event, :live) }
      let(:market) { create(:market, event: event) }
      let(:odd) { create(:odd, market: market) }
      let(:bet) { create(:bet, odd: odd) }

      before { subject }

      it { expect(bet.reload).to be_failed }
    end

    context 'on pre-live provider disconnected' do
      let!(:prematch_producer) { create(:prematch_producer, :unsubscribed) }

      let(:event) { create(:event, :upcoming) }
      let(:market) { create(:market, event: event) }
      let(:odd) { create(:odd, market: market) }
      let(:bet) { create(:bet, odd: odd) }

      before { subject }

      it { expect(bet.reload).to be_failed }
    end

    context 'on market becomes suspended' do
      let(:market) { create(:market, :suspended) }
      let(:odd) { create(:odd, market: market) }
      let(:bet) { create(:bet, odd: odd) }

      before { subject }

      it { expect(bet.reload).to be_failed }
    end

    context 'on unsuccessful entry request' do
      let(:entry_request) { create(:entry_request, origin: bet) }

      before { subject }

      it { expect(bet.reload).to be_failed }
    end
  end
end
