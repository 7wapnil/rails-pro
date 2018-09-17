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
    context 'unexpected bet' do
      let(:invalid_bet) { create(:bet, :pending) }

      subject { described_class.new(invalid_bet) }

      it 'ignores unexpected bet state' do
        allow(subject).to receive(:handle_unexpected_bet)
        subject.handle
        expect(subject).to have_received(:handle_unexpected_bet)
      end
    end

    context 'settled bet' do
      let(:bet) { create(:bet, :settled) }

      subject { described_class.new(bet) }

      it 'handles settled bet' do
        allow(subject).to receive(:handle_unexpected_bet)

        allow(subject).to receive(:create_entry_request)
        allow(subject).to receive(:send_entry_request_for_wallet_authorization)

        subject.handle
        expect(subject).not_to have_received(:handle_unexpected_bet)
        expect(subject).to have_received(:create_entry_request)
        expect(subject).to have_received(:send_entry_request_for_wallet_authorization)
      end
    end
  end

  describe 'handle_unexpected_bet' do
    xit 'handles unexpected bet'
  end

  describe 'create_entry_request' do
    xit 'creates EntryRequest'
  end

  describe 'send_entry_request_for_wallet_authorization' do
    xit 'passes entry request to wallet authorization service'
  end
end
