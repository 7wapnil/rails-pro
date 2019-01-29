describe BetPlacement::SubmissionService do
  subject { described_class.call(bet, impersonated_by) }

  let(:bet)             { build(:bet) }
  let(:rule)            { build_stubbed(:entry_currency_rule) }
  let(:entry)           { create(:entry, origin: bet) }
  let(:impersonated_by) { build(:customer) }
  let(:entry_request)   { build_stubbed(:entry_request, :succeeded) }

  let!(:live_producer) { create(:liveodds_producer) }
  let!(:prematch_producer) { create(:prematch_producer) }

  before do
    allow(EntryRequest).to receive(:create!).and_return(entry_request)
    allow(WalletEntry::AuthorizationService)
      .to receive(:call)
      .with(entry_request)

    allow(EntryCurrencyRule).to receive(:find_by!).and_return(rule)

    allow_any_instance_of(Wallet).to receive(:ratio_with_bonus).and_return(0.75)
    entry
  end

  it 'valid' do
    expect(subject).to be_sent_to_external_validation
  end

  context 'set impersonated person to related entry request' do
    before do
      allow(EntryRequest).to receive(:create!).and_call_original
      allow(WalletEntry::AuthorizationService).to receive(:call)
    end

    it { expect(subject.entry_request.initiator).to eq(impersonated_by) }
  end

  context 'invalid' do
    # TODO: Refactor this nasty trick that mutes expectation state change
    before { allow(bet).to receive(:register_failure!) }

    context 'on failed limits validation' do
      let(:bet)    { build(:bet, :sent_to_internal_validation) }
      let(:errors) { ['error'] }

      before do
        allow(bet).to receive(:send_to_internal_validation!)
        allow(bet).to receive(:errors).and_return(errors)

        allow(BetPlacement::BettingLimitsValidationService)
          .to receive(:call)
          .with(bet)
      end

      it { expect(subject).to be_sent_to_internal_validation }
    end

    context 'on provider disconnected' do
      context 'live' do
        let(:event)  { build(:event, :live) }
        let(:market) { build(:market, event: event) }
        let(:bet)    { build(:bet, market: market) }

        before do
          live_producer.unsubscribed!
          prematch_producer.healthy!
        end

        it { expect(subject).to be_sent_to_internal_validation }
      end

      context 'pre-live' do
        let(:event)  { build(:event, :upcoming) }
        let(:market) { build(:market, event: event) }
        let(:bet)    { build(:bet, market: market) }

        before do
          live_producer.healthy!
          prematch_producer.unsubscribed!
        end

        it { expect(subject).to be_sent_to_internal_validation }
      end
    end

    context 'on market becomes suspended' do
      let(:market) { build(:market, :suspended) }
      let(:bet)    { build(:bet, market: market) }

      it { expect(subject).to be_sent_to_internal_validation }
    end

    context 'on unsuccessful entry request' do
      let(:entry_request) { build_stubbed(:entry_request) }

      it { expect(subject).to be_sent_to_internal_validation }
    end
  end
end
