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
        allow(subject).to receive(:handle_bet)
        subject.handle
        expect(subject).to have_received(:handle_bet)
      end
    end
  end
end
