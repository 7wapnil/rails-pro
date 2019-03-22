describe Markets::PreMatchMarketsClosingService do
  subject { described_class.new }

  let(:delay) do
    ::Markets::PreMatchMarketsClosingService::UPCOMING_EVENT_MINUTES_DELAY
  end

  context '.call' do
    let!(:upcoming_pre_match_event) do
      FactoryBot.create(:event, :with_market, start_at: 1.minute.from_now)
    end
    let!(:upcoming_live_event) do
      FactoryBot.create(:event, :with_market,
                        traded_live: true,
                        start_at: 1.minute.from_now)
    end
    let!(:future_pre_match_event) do
      FactoryBot.create(:event, :with_market,
                        start_at: (delay * 2).minutes.from_now)
    end
    let!(:future_live_event) do
      FactoryBot.create(:event, :with_market,
                        traded_live: true,
                        start_at: (delay * 2).minutes.from_now)
    end

    let(:upcoming_pre_match_event_market) do
      upcoming_pre_match_event.markets.first
    end
    let(:upcoming_live_event_market) do
      upcoming_live_event.markets.first
    end
    let(:future_pre_match_event_market) do
      future_pre_match_event.markets.first
    end
    let(:future_live_event_market) do
      future_live_event.markets.first
    end

    before do
      subject.call
    end

    it 'closes upcoming pre-match markets' do
      expect(upcoming_pre_match_event_market.status).to eq(Market::SUSPENDED)
    end

    it 'doesn\'t close upcoming and future live markets' do
      expect(future_live_event_market.status).to eq(Market::ACTIVE)
    end

    it 'doesn\'t close future pre-match markets' do
      expect(future_pre_match_event_market.status).to eq(Market::ACTIVE)
    end
  end
end
