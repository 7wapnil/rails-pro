require 'services/service_spec'

describe BetSettelement::Service do
  it_behaves_like 'callable service'

  describe 'initialize' do
    let(:bet) { create(:bet) }

    subject { described_class.new(bet) }

    it 'stores bet value' do
      expect(subject.instance_variable_get(:@bet)).to eq(bet)
    end
  end

  describe 'handle' do
    describe 'unexpected bet' do
      context 'pending bet' do
        let(:invalid_bet) { create(:bet, :pending) }

        subject { described_class.new(invalid_bet) }

        it 'ignores unexpected bet state' do
          allow(subject).to receive(:handle_unexpected_bet)
          subject.call
          expect(subject).to have_received(:handle_unexpected_bet)
        end
      end

      context 'lose bet' do
        let(:lose_bet) { create(:bet, :settled, result: false) }

        subject { described_class.new(lose_bet) }

        # TODO: Separate card will introduce refund processing
        it 'ignores lose bet state' do
          allow(subject).to receive(:handle_unexpected_bet)
          subject.call
          expect(subject).to have_received(:handle_unexpected_bet)
        end
      end
    end

    context 'settled bet' do
      let(:bet) { create(:bet, :settled, :win, void_factor: 1) }
      let(:entry_request) { subject.instance_variable_get(:@entry_request) }

      subject { described_class.new(bet) }

      it 'handles settled win bet' do
        allow(subject).to receive(:handle_unexpected_bet)
        allow(subject).to receive(:generate_requests)
        allow(subject).to receive(:apply_requests)

        subject.call
        expect(subject).not_to have_received(:handle_unexpected_bet)
        expect(subject).to have_received(:generate_requests)
        expect(subject).to have_received(:apply_requests)
      end

      xit 'handles settled refund for bet'

      it 'creates EntryRequest from bet' do
        allow(subject).to receive(:apply_requests)

        subject.call

        expect(entry_request).to be_an EntryRequest
        {
          currency: bet.currency,
          kind: 'win',
          mode: 'sports_ticket',
          initiator: bet.customer,
          customer: bet.customer,
          origin: bet
        }.each do |key, value|
          expect(entry_request.send(key)).to eq(value)

          expect(entry_request.amount)
            .to be_within(0.01).of(bet.win_amount)
        end
      end

      it 'passes entry request to wallet authorization service' do
        allow(WalletEntry::AuthorizationService).to receive(:call)

        subject.call

        expect(WalletEntry::AuthorizationService)
          .to have_received(:call).with(entry_request).exactly(1).times
      end
    end
  end

  describe 'handle_unexpected_bet' do
    xit 'handles unexpected bet'
  end
end
