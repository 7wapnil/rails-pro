describe Markets::PreMatchMarketsCloseService do
  subject { described_class.new }
  let(:delay) { ENV.fetch('UPCOMING_EVENT_MINUTES_DELAY') { 5 }.to_i }

  context 'upcoming pre-match event' do
    before do
      @event = FactoryBot.create(:event_with_market, start_at: 1.minute.from_now)
      subject.call
    end

    it 'closes markets' do
      market = Market.where(event: @event).first
      expect(market.status).to eq('suspended')
    end
  end

  context 'not upcoming pre-match event' do
    before do
      @event = FactoryBot.create(:event_with_market, traded_live: true,
                        start_at: (delay * 2).minutes.from_now)
      subject.call
    end

    it 'doesn\'t close markets' do
      market = Market.where(event: @event).first
      expect(market.status).to eq('inactive')
    end
  end

  context 'upcoming live event' do
    before do
      @event = FactoryBot.create(:event_with_market, traded_live: true,
                        start_at: 1.minute.from_now)
      subject.call
    end

    it 'doesn\'t close markets' do
      market = Market.where(event: @event).first
      expect(market.status).to eq('inactive')
    end
  end
end
