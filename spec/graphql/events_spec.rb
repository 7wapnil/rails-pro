describe GraphQL, '#events' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query, context: context, variables: variables)
  end

  let(:title) { create(:title, name: 'Counter-Strike') }

  let(:control_count) { rand(1..4) }
  let(:control_event) {}
  let(:control_events) do
    create_list(:event, control_count, :upcoming, title: title)
  end

  let(:result_events) { result['data']['events'] }
  let(:result_event_ids) { result_events.map { |event| event['id'].to_i } }
  let(:result_event) do
    OpenStruct.new(
      result_events.find { |event| event['id'].to_i == control_event.id }
    )
  end

  before do
    control_events
    control_event
  end

  context 'basic query' do
    let(:control_events) do
      create_list(:event, control_count, :upcoming,
                  visible: true,
                  title: title)
    end

    let(:query) { %({ events { id } }) }

    before { create_list(:event, 3, :upcoming, visible: false, title: title) }

    it 'returns valid events' do
      expect(result_event_ids).to match_array(control_events.map(&:id))
    end
  end

  context 'with market' do
    let(:control_event) { create(:event_with_odds, :upcoming, title: title) }
    let(:control_market) { control_event.dashboard_market }
    let(:control_odds) { control_market.odds }

    let(:result_market) { result_event.dashboard_market }

    let(:query) do
      %({
          events {
            id
            dashboard_market {
              id
              odds { id }
            }
          }
      })
    end

    it 'returns valid market' do
      expect(result_market['id']).to eq(control_market.id.to_s)
    end

    context 'with odds' do
      let(:result_odd_ids) do
        result_market['odds'].map { |odd| odd['id'].to_i }
      end

      it 'returns valid odds' do
        expect(result_odd_ids).to match_array(control_odds.map(&:id))
      end
    end

    context 'without odds' do
      let(:control_event) do
        create(:event_with_market, :upcoming, title: title)
      end

      it 'is not returned' do
        expect(result_event.market).to be_nil
      end
    end

    context 'invisible' do
      let(:control_market) { create(:market, visible: false) }
      let(:control_event) do
        create(:event, :upcoming, title: title, markets: [control_market])
      end

      it 'is not returned' do
        expect(result_event.market).to be_nil
      end
    end
  end

  context 'prioritizes market by priority' do
    let(:control_event) do
      create(:event_with_market, :upcoming, title: title)
    end
    let(:control_market) do
      create(:market, :with_odds,
             priority: Market::PRIORITIES.first,
             event: control_event)
    end

    let(:result_market) { result_event.dashboard_market }

    let(:query) do
      %({
          events {
            id
            dashboard_market { id }
          }
      })
    end

    before do
      create(:market, :with_odds,
             priority: Market::PRIORITIES.third,
             event: control_event)
      control_market
      create(:market, :with_odds,
             priority: Market::PRIORITIES.second,
             event: control_event)
    end

    it 'and returns it' do
      expect(result_market['id']).to eq(control_market.id.to_s)
    end
  end

  context 'ordered by priority' do
    let(:control_events) do
      [
        create(:event, :upcoming, priority: Event::PRIORITIES.second),
        create(:event, :upcoming, priority: Event::PRIORITIES.first),
        create(:event, :upcoming, priority: Event::PRIORITIES.third)
      ]
    end

    let(:sorted_events) { control_events.sort_by(&:priority) }

    let(:query) { %({ events { id priority } }) }

    it 'returns events in valid order' do
      expect(result_event_ids).to eq(sorted_events.map(&:id))
    end
  end

  context 'with limit' do
    let(:limit) { rand(1..control_count) }
    let(:query) do
      %({
          events (limit: #{limit}) {
            id
          }
      })
    end

    it 'returns limited events' do
      expect(result_events.length).to eq(limit)
    end
  end

  context 'with id' do
    let(:control_event) { create(:event, :upcoming) }
    let(:query) do
      %({
          events (filter: { id: #{control_event.id} }) {
            id
          }
      })
    end

    it 'returns single event' do
      expect(result_event_ids).to eq([control_event.id])
    end
  end

  context 'in play' do
    let(:control_events) do
      create_list(:event, control_count,
                  title: title,
                  traded_live: true,
                  start_at: 5.minutes.ago,
                  end_at: nil)
    end

    let(:query) do
      %({
          events (filter: { inPlay: true }) {
            id
          }
      })
    end

    before do
      create_list(:event, 3, :upcoming, title: title)
    end

    it 'returns live events' do
      expect(result_event_ids).to match_array(control_events.map(&:id))
    end
  end

  context 'past' do
    let(:control_events) do
      create_list(:event, control_count,
                  title: title,
                  traded_live: false,
                  start_at: 5.minutes.ago,
                  end_at: nil)
    end

    let(:query) do
      %({
          events (filter: { past: true }) {
            id
          }
      })
    end

    before do
      create_list(:event, 3, :upcoming, title: title)
    end

    it 'returns past events' do
      expect(result_event_ids).to match_array(control_events.map(&:id))
    end
  end

  context 'with title' do
    let(:other_title) { create(:title) }
    let(:query) do
      %({
          events (filter: { titleId: #{title.id} }) {
            id
          }
      })
    end

    before do
      create_list(:event, 3, :upcoming, title: other_title)
    end

    it 'returns events by title ID' do
      expect(result_event_ids).to match_array(control_events.map(&:id))
    end
  end

  context 'tournament' do
    let(:tournament) { create(:event_scope, kind: EventScope::TOURNAMENT) }
    let(:control_events) do
      create_list(:event, control_count, :upcoming,
                  title: title,
                  event_scopes: [tournament])
    end

    let(:query) do
      %({
          events (filter: { tournamentId: #{tournament.id} }) {
            id
          }
      })
    end

    before do
      create_list(:event, 3, :upcoming, title: title)
    end

    it 'returns events by tournament ID' do
      expect(result_event_ids).to match_array(control_events.map(&:id))
    end
  end

  context 'with competitors in payload' do
    let(:competitors) do
      [
        { id: 'sr:competitor:405125', name: 'Melichar N / Peschke K' },
        { id: 'sr:competitor:169832', name: 'Mertens E / Schuurs D' }
      ]
    end
    let(:payload) do
      { competitors: { competitor: competitors } }
    end
    let(:control_event) { create(:event, payload: payload) }

    let(:query) do
      %({
          events {
            id
            competitors { id }
          }
      })
    end

    it 'returns competitors data for respective event' do
      expect(result_event.competitors.length)
        .to eq(competitors.length)
    end
  end

  context 'live' do
    let(:query) { %({ events { id live } }) }

    context 'with SUSPENDED status' do
      let(:control_event) do
        create(:event, traded_live: true, status: Event::SUSPENDED)
      end

      it 'value is truthy' do
        expect(result_event.live).to be_truthy
      end
    end

    context 'in play' do
      let(:control_event) { create(:event, :live) }

      it 'value is truthy' do
        expect(result_event.live).to be_truthy
      end
    end

    context 'without TRADED_LIVE' do
      let(:control_event) { create(:event, status: Event::SUSPENDED) }

      it 'value is falsey' do
        expect(result_event.live).to be_falsey
      end
    end
  end

  context 'with state' do
    let(:control_id) { Faker::Number.number(5) }
    let(:payload) do
      {
        state: { 'id' => control_id },
        producer: {
          origin: 'radar',
          id: '3'
        }
      }
    end

    let(:control_event) do
      create(:event, payload: payload)
    end

    let(:result_state) { OpenStruct.new(result_event.state) }

    let(:query) do
      %({
          events {
            id
            state {
              id
              period_scores { id }
            }
          }
      })
    end

    it 'returns valid state' do
      expect(result_state.id).to eq(control_id)
    end
  end

  context 'without state' do
    let(:payload) do
      {
        producer: {
          origin: 'radar',
          id: '3'
        }
      }
    end

    let(:control_event) do
      create(:event, payload: payload)
    end

    let(:query) do
      %({
          events {
            id
            state {
              id
              period_scores { id }
            }
          }
      })
    end

    it "doesn't return state" do
      expect(result_event.state).to be_nil
    end
  end
end
