# frozen_string_literal: true

describe GraphQL, '#tournamentEvents' do
  let(:result) do
    ArcanebetSchema.execute(query)
  end

  let(:title) { create(:title, name: 'Counter-Strike') }
  let(:tournament) do
    create(:event_scope, kind: EventScope::TOURNAMENT, title: title)
  end

  let(:control_count) { rand(4..7) }
  let(:control_events) do
    (1..control_count).map do
      create(:event, %i[live upcoming].sample, :with_market,
             title: title, event_scopes: [tournament])
    end
  end

  let(:result_by_time) { result&.dig('data', 'tournamentEvents') }
  let(:result_events) do
    [result_by_time['live'], result_by_time['upcoming']].flatten
  end
  let(:result_event_ids) { result_events.map { |event| event['id'].to_i } }

  before { control_events }

  context 'basic query' do
    let(:query) do
      %({
        tournamentEvents(id: #{tournament.id}) {
          live     { id }
          upcoming { id }
        }
      })
    end

    it 'returns valid tournamentEvents' do
      expect(result_event_ids).to match_array(control_events.map(&:id))
    end
  end

  context 'without required params - id' do
    let(:query) do
      %({
        tournamentEvents {
          live     { id }
          upcoming { id }
        }
      })
    end

    it 'raise error params missing' do
      expect(result['errors']).not_to be_empty
    end
  end
end
