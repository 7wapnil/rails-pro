describe EventArchive::Service do
  let(:event) { create(:event) }
  let(:tournament) { create(:event_scope, kind: EventScope::TOURNAMENT) }

  before do
    event.event_scopes << tournament
    event.event_scopes << create(:event_scope, kind: EventScope::CATEGORY)
    event.event_scopes << create(:event_scope, kind: EventScope::SEASON)
  end

  it 'archives event record' do
    described_class.call(event: event)
    archived = ArchivedEvent.find_by(external_id: event.external_id)

    expect(archived).not_to be_nil
    expect(archived.name).to eq(event.name)
    expect(archived.title_name).to eq(event.title.name)
    expect(archived.description).to eq(event.name)
    expect(archived.display_status).to eq(event.display_status)
    expect(archived.home_score).to eq(event.home_score)
    expect(archived.away_score).to eq(event.away_score)
    expect(archived.time_in_seconds).to eq(event.time_in_seconds)
    expect(archived.liveodds).to eq(event.liveodds)
  end

  it 'archives every event scope' do
    described_class.call(event: event)
    archived = ArchivedEvent.find_by(external_id: event.external_id)
    archived_tournament_scope =
      archived.scopes.detect { |scope| scope.kind == EventScope::TOURNAMENT }

    expect(archived.scopes.size).to eq(3)
    expect(archived_tournament_scope.name).to eq(tournament.name)
    expect(archived_tournament_scope.external_id).to eq(tournament.external_id)
  end
end
