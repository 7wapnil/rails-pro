# frozen_string_literal: true

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

    expect(archived).to have_attributes(
      name: event.name,
      title_name: event.title.name,
      meta_description: event.meta_description,
      display_status: event.display_status,
      home_score: event.home_score,
      away_score: event.away_score,
      time_in_seconds: event.time_in_seconds,
      liveodds: event.liveodds
    )
  end

  it 'archives every event scope' do
    described_class.call(event: event)
    archived = ArchivedEvent.find_by(external_id: event.external_id)
    archived_tournament_scope =
      archived.scopes.detect { |scope| scope.kind == EventScope::TOURNAMENT }

    expect(archived.scopes.size).to eq(3)
    expect(archived_tournament_scope).to have_attributes(
      name: tournament.name,
      external_id: tournament.external_id
    )
  end
end
