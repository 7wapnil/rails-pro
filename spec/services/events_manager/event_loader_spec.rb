describe EventsManager::EventLoader do
  subject { described_class.new(external_id) }

  let(:external_id) { 'sr:match:8696826' }

  before do
    allow(EventsManager::EventFetcher).to receive(:call)
  end

  context 'new event' do
    it 'returns crawled event' do
      subject.call

      expect(EventsManager::EventFetcher)
        .to have_received(:call)
        .with(external_id, only_event: false)
    end

    it 'loads event from db after creation' do
      allow(Event).to receive(:find_by).and_call_original
      subject.call
      expect(Event).to have_received(:find_by).twice
    end

    it 'crawls full event when forced' do
      subject.options = { force: true }
      subject.call

      expect(EventsManager::EventFetcher)
        .to have_received(:call)
        .with(external_id, only_event: false)
    end
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

    it 'returns event with associations pre-loaded' do
      allow(Event).to receive(:includes).and_call_original

      includes = %i[title event_scopes]
      subject.options = { includes: includes }
      subject.call

      expect(Event).to have_received(:includes).with(includes)
    end

    it 'returns crawled event, but does not touch associations when forced' do
      subject.options = { force: true }
      subject.call

      expect(EventsManager::EventFetcher)
        .to have_received(:call)
        .with(external_id, only_event: true)
    end
  end
end
