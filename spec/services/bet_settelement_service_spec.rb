describe BetSettelement::Service do
  describe 'behaves like a service' do
    subject { described_class }

    it 'is callable with one argument' do
      expect(subject).to respond_to(:call).with(1).argument
    end
  end

  describe 'initialize' do
    let(:bet) { create(:bet) }

    subject { described_class.new(bet) }

    it 'stores bet value' do
      expect(subject.instance_variable_get(:@bet)).to eq(bet)
    end
  end
end
