describe GraphQL, '#events' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:upcoming_ctx) { 'upcoming_for_time' }
  let(:upcoming_limited_ctx) { 'upcoming_limited' }
  let(:upcoming_unlimited_ctx) { 'upcoming_unlimited' }
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
    let(:query) do
      %({
          events(context: #{upcoming_ctx}) {
            id
            categories { id name count }
          }
      })
    end

    before do
      control_events.each do |event|
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
    end

    it 'returns a list of categories with count' do
      event = result['data']['events'][0]
      categories = event['categories']
      expect(categories.count).to eq(2)

      expect(categories[0]['id'])
        .to eq("#{event['id']}:#{MarketTemplate::POPULAR}")
      expect(categories[0]['count']).to eq(3)

      expect(categories[1]['id'])
        .to eq("#{event['id']}:#{MarketTemplate::PLAYERS}")
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

  context 'with title' do
    let(:other_title) { create(:title) }
    let(:query) do
      %({
          events (
            filter: { titleId: #{title.id} },
            context: #{upcoming_ctx}
          ) { id }
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
          events (
            filter: { tournamentId: #{tournament.id} },
            context: #{upcoming_unlimited_ctx}
          ) { id }
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
    let(:control_event) { create(:event, :upcoming, payload: payload) }
    let!(:tournament) { create(:event_scope) }

    let(:query) do
      %({
          events (
            filter: { tournamentId: #{tournament.id} },
            context: #{upcoming_unlimited_ctx}
          ) {
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
      create(:event, :upcoming, payload: payload)
    end

    let(:result_state) { OpenStruct.new(result_event.state) }

    let(:query) do
      %({
          events(
            filter: { tournamentId: #{tournament.id} },
            context: #{upcoming_unlimited_ctx}
          ) {
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

  context 'with invalid context' do
    let(:query) do
      %({ events(context: abcd) {
          id
          live
    } })
    end

    it 'when context is unsupported raises an error' do
      expect(result['errors']).not_to be_empty
    end

    it 'without context raises an error' do
      query = %({ events{ id } })

      result = ArcanebetSchema.execute(query,
                                       context: context,
                                       variables: variables)
      error_msg = I18n.t(
        'errors.messages.graphql.events.context.invalid',
        context: nil,
        contexts: Events::EventsQueryResolver::SUPPORTED_CONTEXTS.join(', ')
      )

      expect(result['errors'].first['message']).to eq(error_msg)
    end
  end

  it 'context cannot be omitted even when tournament filter is present' do
    tournament = create(:event_scope, :with_event)
    query = %({ events(filter: { tournamentId: #{tournament.id} }) { id } })

    result = ArcanebetSchema.execute(query,
                                     context: context,
                                     variables: variables)

    error_msg = I18n.t(
      'errors.messages.graphql.events.context.invalid',
      context: nil,
      contexts: Events::EventsQueryResolver::SUPPORTED_CONTEXTS.join(', ')
    )

    expect(result['errors'].first['message']).to eq(error_msg)
  end

  context "with 'live' context" do
    let(:query) do
      %({ events(context: #{live_ctx}) { id } })
    end
    let!(:live_events) do
      create_list(:event, rand(1..3), :live, title: title)
    end

    it_behaves_like 'takes only active and visible events' do
      let(:valid_events) { live_events }
    end

    it 'ignores upcoming events' do
      expect(result_event_ids).not_to include(*control_events.map(&:id))
    end

    it 'returns live events' do
      expect(result_event_ids).to match_array(live_events.map(&:id))
    end
  end

  context "with 'upcoming_for_time' context" do
    let(:limit) { Events::EventsQueryResolver::UPCOMING_DURATION }
    let(:query) do
      %({ events(context: #{upcoming_ctx}) { id } })
    end
    let!(:future_events) do
      create_list(:event, rand(1..3), :upcoming,
                  start_at: limit.hours.from_now + 1.minute,
                  title: title)
    end
    let!(:live_events) do
      create_list(:event, rand(1..3), :live, title: title)
    end

    include_context 'frozen_time' do
      let(:frozen_time) { Time.zone.now }
    end

    it_behaves_like 'takes only active and visible events' do
      let(:valid_events) { control_events }
    end

    it 'returns upcoming events up to 24 hours' do
      expect(result_event_ids).to include(*control_events.map(&:id))
    end

    it 'ignores upcoming events which start later than 24 hours from now' do
      expect(result_event_ids).not_to include(*future_events.map(&:id))
    end

    it 'ignores live events' do
      expect(result_event_ids).not_to include(*live_events.map(&:id))
    end
  end

  context "with 'upcoming_limited' context" do
    let(:limit) { Events::EventsQueryResolver::UPCOMING_LIMIT }
    let(:query) do
      %({ events(context: #{upcoming_limited_ctx}) { id } })
    end

    let(:first_tournament) { create(:event_scope, :tournament) }
    let!(:first_tournament_events) do
      create_list(:event, limit + rand(2..4), :upcoming,
                  tournament: first_tournament)
    end

    let(:second_tournament) { create(:event_scope, :tournament) }
    let!(:second_tournament_events) do
      create_list(:event, limit + rand(1..4), :upcoming,
                  tournament: second_tournament)
    end

    let(:live_tournament) { create(:event_scope, :tournament) }
    let!(:live_events) do
      create_list(:event, rand(1..4), :live, tournament: live_tournament)
    end

    let(:tournament_event_ids) do
      first_tournament_events
        .sort_by { |event| [event.priority, event.start_at] }
        .map(&:id)
    end

    let(:included_event_ids) { tournament_event_ids.take(limit) }
    let(:truncated_event_ids) { tournament_event_ids.drop(limit) }

    it_behaves_like 'takes only active and visible events' do
      let(:valid_events) { first_tournament_events }
    end

    it 'returns 16 events per tournament' do
      expect(result_event_ids.length).to eq(limit * 2)
    end

    it 'prioritizes events with higher priority and older start_at' do
      expect(result_event_ids).to include(*included_event_ids)
    end

    it 'truncates events with less priority and more recent start_at' do
      expect(result_event_ids).not_to include(*truncated_event_ids)
    end

    it 'ignores live events' do
      expect(result_event_ids).not_to include(*live_events.map(&:id))
    end
  end

  context "with 'upcoming_unlimited' context" do
    let(:limit) { Events::EventsQueryResolver::UPCOMING_LIMIT }
    let(:duration_limit) { Events::EventsQueryResolver::UPCOMING_DURATION }
    let(:query) do
      %({ events(context: #{upcoming_unlimited_ctx}) { id } })
    end

    let(:tournament) { create(:event_scope, :tournament) }
    let!(:tournament_events) do
      create_list(:event, limit + rand(3..5), :upcoming,
                  tournament: tournament)
    end

    let!(:future_events) do
      create_list(:event, rand(1..4), :upcoming,
                  start_at: duration_limit.hours.from_now + 1.week)
    end

    let!(:live_events) do
      create_list(:event, rand(1..4), :live)
    end

    let(:upcoming_events) do
      [control_events, tournament_events, future_events].flatten
    end

    include_context 'frozen_time' do
      let(:frozen_time) { Time.zone.now }
    end

    it_behaves_like 'takes only active and visible events' do
      let(:valid_events) { upcoming_events }
    end

    it 'returns all upcoming events' do
      expect(result_event_ids).to match_array(upcoming_events.map(&:id))
    end

    it 'ignores live events' do
      expect(result_event_ids).not_to include(*live_events.map(&:id))
    end
  end
end
