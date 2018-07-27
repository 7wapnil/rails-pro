describe OddsFeed::Radar::OddsChangeHandler do
  let(:payload) do
    Nori.new.parse(file_fixture('odds_change_message.xml').read)
  end
  let(:event_id) { payload['odds_change']['@event_id'] }
  let(:event) { build(:event, title: build(:title), external_id: event_id) }
  subject do
    subject = OddsFeed::Radar::OddsChangeHandler.new(payload)
    allow(subject).to receive(:generate_market!)
    allow(subject).to receive(:request_event).and_return(event)
    subject
  end

  it 'should not store event in db if already exists' do
    create(:event, external_id: event_id)
    allow(subject).to receive(:create_event)
    subject.handle

    expect(subject).not_to have_received(:create_event)
  end

  it 'should request event data from API if not found in db' do
    subject.handle
    expect(subject)
      .to have_received(:request_event).with(event_id)
  end

  it 'should store event in db from API request data' do
    allow(event).to receive(:save!)
    subject.handle
    expect(event).to have_received(:save!)
  end

  it 'should call market generator for every market data row' do
    subject.handle
    expect(subject)
      .to have_received(:generate_market!)
            .exactly(5)
            .times
  end
end
