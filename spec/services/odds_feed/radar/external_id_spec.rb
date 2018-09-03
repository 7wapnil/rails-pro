describe OddsFeed::Radar::ExternalId do
  it 'generates id from all parts' do
    subject.event_id = 'sr:event'
    subject.market_id = 'mid'
    subject.specs = 'score=45|set=2'
    subject.outcome_id = '111'

    expect(subject.generate).to eq('sr:event:mid/score=45|set=2:111')
  end

  it 'generates no spec id' do
    subject.event_id = 'sr:event'
    subject.market_id = 'mid'
    subject.outcome_id = '111'

    expect(subject.generate).to eq('sr:event:mid:111')
  end

  it 'generates partial id' do
    subject.event_id = 'sr:event'
    subject.market_id = 'mid'

    expect(subject.generate).to eq('sr:event:mid')
  end
end
