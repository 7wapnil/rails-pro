describe EventsManager::EventLoader do
  subject { described_class.new(external_id) }

  let(:external_id) { 'sr:match:8696826' }

  before do
    allow(EventsManager::EventFetcher).to receive(:call)
  end

  it 'returns crawled event' do
    subject.call

    expect(EventsManager::EventFetcher)
      .to have_received(:call)
      .with(external_id)
  end

  context 'existing event' do
    before do
      create(:event, external_id: external_id)
    end

    it 'returns event from local database' do
      subject.call
      expect(EventsManager::EventFetcher)
        .not_to have_received(:call)
    end

    it 'returns event from database with associations' do
      allow(::Event).to receive(:includes).and_call_original

      subject.options = { includes: %i[competitors players] }
      subject.call

      expect(::Event)
        .to have_received(:includes)
        .with(%i[competitors players])
    end

    it 'returns crawled event when forced' do
      subject.options = { force: true }
      subject.call

      expect(EventsManager::EventFetcher)
        .to have_received(:call)
        .with(external_id)
    end
  end
end
