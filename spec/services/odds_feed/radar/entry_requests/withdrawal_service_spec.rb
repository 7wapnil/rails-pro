# frozen_string_literal: true

describe EntryRequests::WithdrawalService do
  subject { described_class.call(entry_request: entry_request) }

  let(:bet)             { create(:bet) }
  let(:rule)            { create(:entry_currency_rule) }
  let!(:entry)          { create(:entry, origin: bet) }
  let(:impersonated_by) { create(:customer) }
  let(:entry_request) do
    create(:entry_request, :succeeded,
           origin: bet,
           initiator: bet.customer,
           amount: bet.amount,
           currency: bet.currency,
           kind: EntryRequest::BET,
           mode: EntryRequest::SYSTEM)
  end

  let!(:live_producer) { create(:liveodds_producer) }
  let!(:prematch_producer) { create(:prematch_producer) }

  before do
    allow(WalletEntry::AuthorizationService)
      .to receive(:call)
      .with(entry_request)

    allow(EntryCurrencyRule).to receive(:find_by!).and_return(rule)

    allow_any_instance_of(Wallet).to receive(:ratio_with_bonus).and_return(0.75)
  end

  it 'valid' do
    subject
    expect(bet).to be_sent_to_external_validation
  end

  context 'invalid' do
    # TODO: Refactor this nasty trick that mutes expectation state change
    before { allow(bet).to receive(:register_failure!) }

    context 'on failed limits validation' do
      let(:bet) { create(:bet, :sent_to_internal_validation) }
      let(:errors) { ['error'] }

      before do
        allow(bet).to receive(:send_to_internal_validation!)
        allow(bet).to receive(:errors).and_return(errors)

        allow(BetPlacement::BettingLimitsValidationService)
          .to receive(:call)
          .with(bet)

        subject
      end

      it { expect(bet).to be_sent_to_internal_validation }
    end

    context 'on live provider disconnected' do
      let(:event) { build(:event, :live) }
      let(:market) { build(:market, event: event) }
      let(:bet) { build(:bet, market: market) }

      before do
        live_producer.unsubscribed!
        prematch_producer.healthy!

        subject
      end

      it { expect(bet).to be_sent_to_internal_validation }
    end

    context 'on pre-live provider disconnected' do
      let(:event)  { build(:event, :upcoming) }
      let(:market) { build(:market, event: event) }
      let(:bet)    { build(:bet, market: market) }

      before do
        live_producer.healthy!
        prematch_producer.unsubscribed!

        subject
      end

      it { expect(bet).to be_sent_to_internal_validation }
    end

    context 'on market becomes suspended' do
      let(:market) { build(:market, :suspended) }
      let(:bet)    { build(:bet, market: market) }

      before { subject }

      it { expect(bet).to be_sent_to_internal_validation }
    end

    context 'on unsuccessful entry request' do
      let(:entry_request) { build(:entry_request, origin: bet) }

      before { subject }

      it { expect(bet).to be_sent_to_internal_validation }
    end
  end
end
