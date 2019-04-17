describe UnpopularEventsCleanUpWorker do
  it 'deletes finished live events' do
    create(:event, end_at: 25.hours.ago)
    subject.perform
    expect(Event.count).to eq(0)
  end

  it 'doesn\'t delete not finished live events' do
    create(:event,
           start_at: 5.minutes.ago,
           end_at: nil)
    subject.perform
    expect(Event.count).to eq(1)
  end

  it 'doesn\'t delete events finished less than a day ago' do
    create(:event,
           start_at: 26.hours.ago,
           end_at: 23.hours.ago)
    subject.perform
    expect(Event.count).to eq(1)
  end

  it 'doesn\'t delete events with :end_at in future' do
    create(:event, traded_live: true, end_at: 5.minutes.from_now)
    subject.perform
    expect(Event.count).to eq(1)
  end
end
