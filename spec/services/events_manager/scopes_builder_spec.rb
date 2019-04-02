describe EventsManager::ScopesBuilder do
  subject { described_class.new(event, event_entity) }

  let(:event) { create(:event, external_id: 'sr:match:8696826') }
  let(:event_payload) do
    ::XmlParser.parse(file_fixture('radar_event_fixture.xml').read)
  end
  let(:event_entity) do
    EventsManager::Entities::Event.new(event_payload)
  end

  context 'build' do
    it 'creates all scopes' do
      subject.build
      expect(EventScope.count).to eq(3)
    end

    it 'updates on duplicate' do
      create(:event_scope,
             external_id: 'sr:tournament:68',
             kind: EventScope::TOURNAMENT)

      create(:event_scope,
             external_id: 'sr:season:12346',
             kind: EventScope::SEASON)

      create(:event_scope,
             external_id: 'sr:category:9',
             kind: EventScope::CATEGORY)

      subject.build
      expect(EventScope.count).to eq(3)
    end

    it 'binds scopes to title' do
      EventScope.all.each do |scope|
        expect(scope.title.id).to eq(event.title.id)
      end
    end

    it 'binds tournament to category' do
      subject.build
      scope = EventScope.find_by!(kind: EventScope::TOURNAMENT)
      expect(scope.event_scope.external_id).to eq('sr:category:9')
    end

    it 'binds season to tournament' do
      subject.build
      scope = EventScope.find_by!(kind: EventScope::SEASON)
      expect(scope.event_scope.external_id).to eq('sr:tournament:68')
    end
  end

  context 'exceptions' do
    before do
      allow(event_entity).to receive(:category).and_return(nil)
      allow(event_entity).to receive(:tournament).and_return(nil)
      allow(event_entity).to receive(:season).and_return(nil)
    end

    it 'skips scope creation on empty fixture' do
      subject.build
      expect(EventScope.count).to eq(0)
    end
  end
end
