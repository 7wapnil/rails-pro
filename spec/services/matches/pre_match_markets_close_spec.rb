describe Markets::PreMatchMarketsCloseService do
  subject { described_class.new }
  let(:delay) { ENV.fetch('UPCOMING_EVENT_MINUTES_DELAY') { 5 }.to_i }

  it 'calls Markets::PreMatchMarketsCloseService' do
    subject.call
  end

  it 'closes markets of upcoming pre-match events' do
    FactoryBot.create(:event_with_market, start_at: 1.minute.from_now)
    expect(subject.call).to eq(1)
  end

  it 'doesn\'t close markets of not upcoming pre-match events' do
    FactoryBot.create(:event_with_market, :live,
                      start_at: (delay * 2).minutes.from_now)
    expect(subject.call).to eq(0)
  end

  it 'doesn\'t close markets of upcoming live events' do
    FactoryBot.create(:event_with_market, :live, start_at: 1.minute.from_now)
    expect(subject.call).to eq(0)
  end
end
