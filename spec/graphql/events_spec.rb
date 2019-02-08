describe GraphQL, '#events' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:upcoming_ctx) { 'upcoming_for_time' }
  let(:upcoming_limited_ctx) { 'upcoming_limited' }
  let(:live_ctx) { 'live' }

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

    let(:query) { %({ events(context: #{upcoming_ctx}) { id } }) }

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
          events(context: #{upcoming_ctx}) {
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

  context 'with categories' do
    let(:event) { create(:event, :upcoming, title: title) }
    let(:query) do
      %({
          events(context: #{upcoming_ctx}, filter: { id: #{event.id} }) {
            id
            categories { id name count }
          }
      })
    end

    before do
      create_list(:market,
                  3,
                  :with_odds,
                  event: event,
                  category: MarketTemplate::POPULAR)
      create_list(:market,
                  2,
                  :with_odds,
                  event: event,
                  category: MarketTemplate::PLAYERS)
      create_list(:market,
                  1,
                  :with_odds,
                  event: event,
                  category: nil)
    end

    it 'returns a list of categories with count' do
      categories = result['data']['events'][0]['categories']
      expect(categories.count).to eq(2)

      expect(categories[0]['id']).to eq(MarketTemplate::POPULAR)
      expect(categories[0]['count']).to eq(3)

      expect(categories[1]['id']).to eq(MarketTemplate::PLAYERS)
      expect(categories[1]['count']).to eq(2)
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
          events(context: #{upcoming_ctx}) {
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

    let(:query) { %({ events(context: #{upcoming_ctx}) { id priority } }) }

    it 'returns events in valid order' do
      expect(result_event_ids).to eq(sorted_events.map(&:id))
    end
  end

  context 'with id' do
    let(:control_event) { create(:event, :upcoming) }
    let(:query) do
      %({
          events (context: #{upcoming_ctx},
                  filter: { id: #{control_event.id} }) {
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
          events (context: #{live_ctx}) {
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

    let!(:tournament) { create(:event_scope, :tournament) }
    let(:query) do
      %({
          events (filter: { past: true, tournamentId: #{tournament.id} }) {
            id
          }
      })
    end

    before do
      create_list(:event, 3, :upcoming, title: title)

      control_events.each do |event|
        ScopedEvent.create(event: event, event_scope: tournament)
      end
    end

    it 'returns past events' do
      expect(result_event_ids).to match_array(control_events.map(&:id))
    end
  end

  context 'with title' do
    let(:other_title) { create(:title) }
    let(:query) do
      %({
          events (context: #{upcoming_ctx}, filter: { titleId: #{title.id} }) {
            id
          }
      })
    end

    before do
      create_list(:event, 3, :upcoming, title: other_title)
    end

    it 'returns events by title ID' do
      pp result
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
    let!(:tournament) { create(:event_scope) }

    let(:query) do
      %({
          events(filter: { tournamentId: #{tournament.id} }) {
            id
            competitors { id }
          }
      })
    end

    it 'returns competitors data for respective event' do
      ScopedEvent.create(event: control_event, event_scope: tournament)

      expect(result_event.competitors.length)
        .to eq(competitors.length)
    end
  end

  context 'category' do
    let(:category) { create(:event_scope, kind: EventScope::CATEGORY) }
    let(:query) do
      %({ events (
            filter: { categoryId: #{category.id} }
            context: #{upcoming_ctx}
        ) {
            id
      } })
    end

    before do
      other_title = create(:title)
      create_list(:event, 5, :upcoming, title: other_title)

      events = create_list(
        :event, 5, :upcoming,
        title: category.title
      )

      events.each do |event|
        event.event_scopes << category
      end
    end

    it 'returns events by category ID' do
      expect(result['data']).not_to be_nil
      expect(result['data']['events'].length).to eq(5)
    end
  end

  context 'live' do
    let(:query) { %({ events(context: #{live_ctx}) { id live } }) }

    context 'with SUSPENDED status' do
      let(:control_event) do
        create(:event, :live)
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
    let!(:tournament) { create(:event_scope) }
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
          events(filter: { tournamentId: #{tournament.id}}) {
            id
            state {
              id
              period_scores { id }
            }
          }
      })
    end

    it 'returns valid state' do
      ScopedEvent.create(event: control_event, event_scope: tournament)

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
          events(context: #{upcoming_ctx}) {
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

  describe 'context usage' do
    include_context 'frozen_time'
    context 'returns errors' do
      let(:query) do
        %({ events(context: abcd) {
            id
            live
      } })
      end

      it 'pass unsupported context' do
        expect(result['errors']).not_to be_empty
      end

      it 'calls without context' do
        query = %({ events{ id } })

        result = ArcanebetSchema.execute(query,
                                         context: context,
                                         variables: variables)
        error_msg = Events::EventsQueryResolver::CONTEXT_REQUIRED_ERROR_MSG

        expect(result['errors'].first['message']).to eq(error_msg)
      end
    end

    it 'context can be omitted when tournament filter is present' do
      tournament = create(:event_scope, :with_event)
      query = %({ events(filter: { tournamentId: #{tournament.id} }){ id } })

      result = ArcanebetSchema.execute(query,
                                       context: context,
                                       variables: variables)

      expect(result['errors']).to be_nil
    end

    it "'calls with 'live' context" do
      query = %({ events(context: live){ id } })
      create_list(:event, 5)
      live_event = create(:event, :live)
      result = ArcanebetSchema.execute(query,
                                       context: context,
                                       variables: variables)
      event_ids = result['data']['events'].map { |event| event['id'].to_i }

      expect(event_ids).to match_array([live_event.id])
    end

    it "calls with 'upcoming_for_time' context" do
      query = %({ events(context: #{upcoming_ctx}){ id } })

      upcoming_events_ids = create_list(:event, 2, :upcoming).map(&:id)
      create_list(:event, 2, start_at: 1.day.from_now + 1.minute, end_at: nil)
      create_list(:event, 2, start_at: 1.minute.ago, end_at: nil)
      result = ArcanebetSchema.execute(query,
                                       context: context,
                                       variables: variables)
      result_ids = result['data']['events'].map { |event| event['id'].to_i }

      expect(result_ids).to match_array(upcoming_events_ids)
    end

    it "calls with 'upcoming_limited' context" do
      query = %({ events(context: #{upcoming_limited_ctx}){ id } })
      limit = Events::EventsQueryResolver::UPCOMING_LIMIT
      upcoming_events_ids = create_list(:event, limit + 2, :upcoming).map(&:id)
      create_list(:event, 5)
      result = ArcanebetSchema.execute(query,
                                       context: context,
                                       variables: variables)
      result_ids = result['data']['events'].map { |event| event['id'].to_i }
      upcoming_result_ids = upcoming_events_ids & result_ids

      expect(upcoming_result_ids.length).to eq(limit)
    end
  end
end
