describe OddsFeed::Radar::ScheduledEvents::IdEventLoader do
  subject { service_object.call }

  let(:event_id) { "sr:match:#{Faker::Number.decimal(8)}" }
  let(:service_object) { described_class.new(event_id) }
  let(:mock) { instance_double('loader') }

  before do
    allow(EventsManager::EventLoader)
      .to receive(:new)
      .with(event_id)
      .and_return(mock)
    allow(mock).to receive(:call)
    subject
  end

  it 'calls EventLoader for given event_id' do
    expect(mock).to have_received(:call)
  end
end
