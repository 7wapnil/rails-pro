describe BetPlacement::SubmissionService do
  subject { described_class.call(bet, impersonated_by) }

  let(:bet)             { build(:bet) }
  let(:rule)            { build_stubbed(:entry_currency_rule) }
  let(:entry)           { create(:entry, origin: bet) }
  let(:impersonated_by) { build(:customer) }
  let(:entry_request)   { build_stubbed(:entry_request, :succeeded) }

  before do
    allow(ApplicationState)
      .to receive(:instance)
      .and_return(instance_double(ApplicationState, live_connected: true))
    allow(EntryRequest).to receive(:create!).and_return(entry_request)
    allow(WalletEntry::AuthorizationService)
      .to receive(:call)
      .with(entry_request)

    allow(EntryCurrencyRule).to receive(:find_by!).and_return(rule)
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
        before do
          allow(ApplicationState)
            .to receive(:instance)
            .and_return(instance_double(ApplicationState,
                                        live_connected: false))
        end

        it { expect(subject).to be_sent_to_internal_validation }
      end

      context 'pre-live' do
        let(:event)  { build(:event, traded_live: true) }
        let(:market) { build(:market, event: event) }
        let(:bet)    { build(:bet, market: market) }

        before do
          allow(ApplicationState)
            .to receive(:instance)
            .and_return(instance_double(ApplicationState,
                                        live_connected: true,
                                        pre_live_connected: false))
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
