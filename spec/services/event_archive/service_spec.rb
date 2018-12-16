describe EventArchive::Service do
  let(:event) { create(:event) }
  let(:tournament) { create(:event_scope, kind: EventScope::TOURNAMENT) }

  before do
    event.event_scopes << tournament
    event.event_scopes << create(:event_scope, kind: EventScope::COUNTRY)
    event.event_scopes << create(:event_scope, kind: EventScope::SEASON)
  end

  it 'archives event record' do
    described_class.call(event: event)
    archived = ArchivedEvent.find_by(external_id: event.external_id)

    expect(archived).not_to be_nil
    expect(archived.name).to eq(event.name)
    expect(archived.title_name).to eq(event.title.name)
    expect(archived.description).to eq(event.name)
    expect(archived.payload).to eq(event.payload)
  end

  it 'archives every event scope' do
    described_class.call(event: event)
    archived = ArchivedEvent.find_by(external_id: event.external_id)

    expect(archived.scopes.size).to eq(3)
    expect(archived.scopes[0].name).to eq(tournament.name)
    expect(archived.scopes[0].external_id).to eq(tournament.external_id)
    expect(archived.scopes[0].kind).to eq(tournament.kind)
  end
end
