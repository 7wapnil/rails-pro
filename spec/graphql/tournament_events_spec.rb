# frozen_string_literal: true

describe GraphQL, '#tournamentEvents' do
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }
  let(:cache) { Rails.cache }

  let(:context) { {} }
  let(:variables) { {} }
  let(:upcoming_ctx) { 'upcoming' }
  let(:live_ctx) { 'live' }
  let(:upcoming_and_live_ctx) { 'upcoming_and_live' }

  let(:result) do
    ArcanebetSchema.execute(query, context: context, variables: variables)
  end

  let(:title) { create(:title, name: 'Counter-Strike') }
  let(:tournament) do
    create(:event_scope, kind: EventScope::TOURNAMENT, title: title)
  end

  let(:control_count) { rand(4..7) }
  let(:control_event_scopes) { [tournament] }
  let(:control_event_markets) { [] }
  let(:control_event_traits) { [:upcoming] }
  let(:control_event) do
    create :event,
           *control_event_traits,
           tournament: tournament,
           event_scopes: control_event_scopes,
           markets: control_event_markets
  end
  let(:control_events) do
    (1..control_count).map do
      create(:event, %i[live upcoming].sample, :with_market,
             title: title, event_scopes: [tournament])
    end
  end

  let(:result_events) { result&.dig('data', 'tournamentEvents') }
  let(:result_event_ids) { result_events.map { |event| event['id'].to_i } }
  let(:result_event) do
    OpenStruct.new(
      result_events&.find { |event| event['id'].to_i == control_event.id }
    )
  end

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear

    control_events
    control_event
  end

  context 'basic query' do
    let(:query) do
      %({
        tournamentEvents(id: #{tournament.id},
                         context: #{upcoming_and_live_ctx}) {
          id
        }
      })
    end

    it 'returns valid tournamentEvents' do
      expect(result_event_ids).to match_array(control_events.map(&:id))
    end
  end

  context 'with upcoming context' do
    let(:query) do
      %({
      tournamentEvents(id: #{tournament.id}, context: #{upcoming_ctx}) { id }
    })
    end

    it 'only upcoming tournamentEvents' do
      expect(result_event_ids)
        .to match_array(tournament.events.upcoming.pluck(:id))
    end
  end

  context 'with live context' do
    let(:query) do
      %({
      tournamentEvents(id: #{tournament.id}, context: #{live_ctx}) { id }
    })
    end

    it 'only live tournamentEvents' do
      expect(result_event_ids)
        .to match_array(tournament.events.in_play.pluck(:id))
    end
  end
end
