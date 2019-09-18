# frozen_string_literal: true

describe GraphQL, '#eventContexts' do
  let(:result) do
    ArcanebetSchema.execute(query, context: {}, variables: {})
  end
  let(:result_event_contexts) { result.to_h.dig('data', 'eventContexts') }

  let(:title) { create(:title, name: 'Counter-Strike') }
  let(:tournament) { create(:event_scope, kind: EventScope::TOURNAMENT) }
  let(:control_events_trait) { :live }
  let(:control_events) do
    create_list(:event, 10, control_events_trait, :with_market,
                title: title, event_scopes: [tournament])
  end
  let(:all_contexts) { Events::EventsQueryResolver::SUPPORTED_CONTEXTS }

  let(:query) do
    %({ eventContexts(contexts: [#{all_contexts.join(', ')}]) {
          context
          show
        }
      })
  end

  context 'live' do
    let(:control_results) do
      [
        {
          'context' => 'live',
          'show' => true
        },
        {
          'context' => 'upcoming_unlimited',
          'show' => false
        }
      ]
    end

    before { control_events }

    it 'returns valid response' do
      expect(result_event_contexts).to include(*control_results)
    end
  end

  context 'upcoming' do
    let(:control_events_trait) { :upcoming }
    let(:control_results) do
      [
        {
          'context' => 'live',
          'show' => false
        },
        {
          'context' => 'upcoming_unlimited',
          'show' => true
        }
      ]
    end

    before { control_events }

    it 'returns valid response' do
      expect(result_event_contexts).to include(*control_results)
    end
  end
end
