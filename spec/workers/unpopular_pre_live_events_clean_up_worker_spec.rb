describe UnpopularPreLiveEventsCleanUpWorker do
  it 'includes finished pre live events' do
    create(:event, start_at: 25.hours.ago)
    subject.perform
    expect(Event.count).to eq(0)
  end

  it 'doesn\'t delete not started pre live events' do
    create(:event, start_at: 5.minutes.from_now)
    subject.perform
    expect(Event.count).to eq(1)
  end

  it 'doesn\'t delete pre live events started less than a day ago' do
    create(:event, start_at: 23.hours.ago)
    subject.perform
    expect(Event.count).to eq(1)
  end

  it 'doesn\'t delete live events' do
    create(:event, traded_live: true, start_at: 25.hours.ago)
    subject.perform
    expect(Event.count).to eq(1)
  end

  it 'doesn\'t delete pre live events with :start_at in future' do
    create(:event, start_at: 10.minutes.from_now)
    subject.perform
    expect(Event.count).to eq(1)
  end
end
