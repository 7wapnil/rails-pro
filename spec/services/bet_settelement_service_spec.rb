describe BetSettelement::Service do
  describe 'behaves like a service' do
    it 'is callable with one argument' do
      expect(described_class).to respond_to(:call).with(1).argument
    end

    it 'responds to handle method' do
      expect(described_class.new(double))
        .to respond_to(:handle).with(0).argument
    end
  end

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
          subject.handle
          expect(subject).to have_received(:handle_unexpected_bet)
        end
      end

      context 'lose bet' do
        let(:lose_bet) { create(:bet, :settled, result: false) }

        subject { described_class.new(lose_bet) }

        it 'ignores lose bet state' do
          allow(subject).to receive(:handle_unexpected_bet)
          subject.handle
          expect(subject).to have_received(:handle_unexpected_bet)
        end
      end
    end

    context 'settled bet' do
      let(:bet) { create(:bet, :settled, :win, void_factor: 1) }

      subject { described_class.new(bet) }

      it 'handles settled win bet' do
        allow(subject).to receive(:handle_unexpected_bet)

        allow(subject).to receive(:generate_requests)
        allow(subject).to receive(:apply_requests)

        subject.handle
        expect(subject).not_to have_received(:handle_unexpected_bet)
        expect(subject).to have_received(:generate_requests)
        expect(subject).to have_received(:apply_requests)
      end

      let(:entry_request) { subject.instance_variable_get(:@entry_request) }

      it 'creates EntryRequest from bet' do
        allow(subject).to receive(:apply_requests)

        subject.handle

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
            .to be_within(0.01).of(bet.outcome_amount)
        end
      end
    end
  end

  describe 'handle_unexpected_bet' do
    xit 'handles unexpected bet'
  end

  describe 'send_entry_request_for_wallet_authorization' do
    xit 'passes entry request to wallet authorization service'
  end
end
