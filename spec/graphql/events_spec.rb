# frozen_string_literal: true

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
  let(:tournament) { create(:event_scope, kind: EventScope::TOURNAMENT) }

  let(:control_count) { rand(1..4) }
  let(:control_event_scopes) { [tournament] }
  let(:control_event_markets) { [] }
  let(:control_event_traits) { [:upcoming] }
  let(:control_event) do
    create :event,
           *control_event_traits,
           title: title,
           event_scopes: control_event_scopes,
           markets: control_event_markets
  end
  let(:control_events) do
    create_list(:event, control_count, :upcoming, :with_market,
                title: title, event_scopes: [tournament])
  end

  let(:result_events) { result&.dig('data', 'events') }
  let(:result_event_ids) { result_events.map { |event| event['id'].to_i } }
  let(:result_event) do
    OpenStruct.new(
      result_events&.find { |event| event['id'].to_i == control_event.id }
    )
  end

  before do
    control_events
    control_event
  end

  context 'basic query' do
    let(:control_event) {}
    let(:query) { %({ events(context: #{upcoming_ctx}) { id } }) }

    before { create_list(:event, 3, :upcoming, visible: false, title: title) }

    it 'returns valid events' do
      expect(result_event_ids).to match_array(control_events.map(&:id))
    end
  end

  context 'with market' do
    let(:control_event_traits) { %i[with_odds upcoming] }
    let(:control_market) { control_event.dashboard_markets.first }
    let(:control_odds) { control_market.odds }

    let(:result_market) { result_event.dashboardMarket }

    let(:query) do
      %({
          events(context: #{upcoming_ctx}) {
            id
            dashboardMarket {
              id
              odds { id }
            }
          }
      })
    end

    it 'returns valid market' do
      expect(result_market['id']).to eq(control_market.id.to_s)
    end

    context 'with markets_count' do
      let(:control_count) { rand(2..5) }
      let(:control_events) {}
      let(:control_event_traits) { [:upcoming] }

      let(:query) do
        %({ events(context: #{upcoming_ctx}) { id marketsCount } })
      end

      before do
        create_list(:market, rand(1..3), event: control_event,
                                         status: Market::ACTIVE)
        create_list(:market, control_count, :with_odds, event: control_event,
                                                        status: Market::ACTIVE)
        create_list(:market, rand(1..3), :with_inactive_odds,
                    event: control_event, status: Market::INACTIVE)
        create_list(:market, rand(1..3), :with_odds, visible: false,
                                                     event: control_event,
                                                     status: Market::INACTIVE)
      end

      it 'returns valid markets count' do
        expect(result_event.marketsCount).to eq(control_count)
      end
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
      let(:control_event_traits) { %i[with_market upcoming] }

      it 'is not returned' do
        expect(result_event.dashboardMarket).to be_nil
      end
    end

    context 'invisible' do
      let(:control_market) do
        create(:market, visible: false, status: Market::ACTIVE)
      end
      let(:control_event_traits) { [:upcoming] }
      let(:control_event_markets) { [control_market] }

      it 'is not returned' do
        expect(result_event.dashboardMarket).to be_nil
      end
    end
  end

  context 'without market' do
    let(:control_event) do
      create :event,
             *control_event_traits,
             title: title,
             event_scopes: control_event_scopes
    end
    let(:control_events) do
      create_list(:event, control_count, :upcoming,
                  title: title, event_scopes: [tournament])
    end

    let(:query) do
      %({
          events(context: #{upcoming_ctx}) {
            id
            dashboardMarket {
              id
              odds { id }
            }
          }
      })
    end

    it 'does not return events' do
      expect(result_events).to be_empty
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

    let(:players_template) do
      create(:market_template, category: MarketTemplate::PLAYERS)
    end
    let(:template_without_category) { create(:market_template, category: nil) }

    before do
      control_events.each do |event|
        create_list(:market,
                    3,
                    :with_odds,
                    :with_template,
                    event: event,
                    status: Market::ACTIVE)
        create_list(:market,
                    2,
                    :with_odds,
                    event: event,
                    status: Market::ACTIVE,
                    template: players_template)
        create(:market, :with_odds,
               event: event,
               status: Market::ACTIVE,
               template: template_without_category)
        create(:market, :with_odds,
               event: event,
               status: Market::ACTIVE)
      end
    end

    it 'returns a list of categories with count' do
      event = result['data']['events'][0]
      categories = event['categories'].sort_by { |category| category['name'] }
      expect(categories.length).to eq(2)

      expect(categories[0]['id'])
        .to eq("#{event['id']}:#{MarketTemplate::PLAYERS}")
      expect(categories[0]['count']).to eq(2)

      expect(categories[1]['id'])
        .to eq("#{event['id']}:#{MarketTemplate::POPULAR}")
      expect(categories[1]['count']).to eq(3)
    end
  end

  context 'prioritizes market by priority' do
    let(:control_event_traits) { %i[with_market upcoming] }
    let(:control_market) do
      create(:market, :with_odds, priority: Market::PRIORITIES.first,
                                  event: control_event,
                                  status: Market::ACTIVE)
    end

    let(:result_market) { result_event.dashboardMarket }

    let(:query) do
      %({
          events(context: #{upcoming_ctx}) {
            id
            dashboardMarket { id }
          }
      })
    end

    before do
      create(:market, :with_odds,
             priority: Market::PRIORITIES.third,
             status: Market::ACTIVE,
             event: control_event)
      control_market
      create(:market, :with_odds,
             priority: Market::PRIORITIES.second,
             status: Market::ACTIVE,
             event: control_event)
    end

    it 'and returns it' do
      expect(result_market['id']).to eq(control_market.id.to_s)
    end
  end

  context 'ordered by priority' do
    let(:control_event) {}
    let(:control_events) do
      [
        create(:event, :with_market, :upcoming,
               priority: Event::PRIORITIES.second,
               event_scopes: [tournament]),
        create(:event, :with_market, :upcoming,
               priority: Event::PRIORITIES.first,
               event_scopes: [tournament]),
        create(:event, :with_market, :upcoming,
               priority: Event::PRIORITIES.third,
               event_scopes: [tournament])
      ]
    end

    let(:sorted_events) { control_events.sort_by(&:priority) }

    let(:query) { %({ events(context: #{upcoming_ctx}) { id priority } }) }

    it 'returns events in valid order' do
      expect(result_event_ids).to eq(sorted_events.map(&:id))
    end
  end

  context 'with title' do
    let(:control_event) {}
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
      create_list(:event, 3, :with_market, :upcoming,
                  title: other_title, event_scopes: [tournament])
    end

    it 'returns events by title ID' do
      pp result
      expect(result_event_ids).to match_array(control_events.map(&:id))
    end
  end

  context 'tournament' do
    let(:control_event) {}
    let(:query) do
      %({
          events (
            filter: { tournamentId: #{tournament.id} },
            context: #{upcoming_unlimited_ctx}
          ) { id }
      })
    end

    before do
      create_list(:event, 3, :with_market, :upcoming, title: title)
    end

    it 'returns events by tournament ID' do
      expect(result_event_ids).to match_array(control_events.map(&:id))
    end
  end

  context 'with competitors in payload' do
    let(:control_event_traits) { %i[with_market upcoming] }
    let!(:tournament) { create(:event_scope) }
    let(:competitors) do
      [
        create(:competitor, external_id: 'sr:competitor:405125',
                            name: 'Melichar N / Peschke K'),
        create(:competitor, external_id: 'sr:competitor:169832',
                            name: 'Mertens E / Schuurs D')
      ]
    end
    let!(:event_competitors) do
      competitors.map do |competitor|
        create(:event_competitor, competitor: competitor, event: control_event)
      end
    end

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
      create_list(:event, 5, :with_market, :upcoming,
                  title: other_title, event_scopes: [tournament])

      create_list(:event, 5, :with_market, :upcoming,
                  title: category.title, event_scopes: [category, tournament])
    end

    it 'returns events by category ID' do
      expect(result['data']).not_to be_nil
      expect(result['data']['events'].length).to eq(5)
    end
  end

  context 'start status' do
    let(:query) { %({ events(context: #{ctx}) { id startStatus } }) }
    let(:ctx) { 'live' }

    context 'with SUSPENDED status' do
      let(:control_event_traits) { %i[with_market live] }

      it 'value is LIVE' do
        expect(result_event.startStatus).to eq Event::LIVE
      end
    end

    context 'in play' do
      let(:control_event_traits) { %i[with_market live] }

      it 'value is LIVE' do
        expect(result_event.startStatus).to eq Event::LIVE
      end
    end

    context 'without TRADED_LIVE' do
      let(:control_event_traits) { %i[with_market] }

      before do
        control_event.status = Event::SUSPENDED
      end

      it 'value is nil' do
        expect(result_event.startStatus).to be_nil
      end
    end

    context 'when upcoming' do
      let(:ctx) { 'upcoming_unlimited' }
      let(:control_event_traits) { %i[with_market upcoming] }

      it 'value is UPCOMING' do
        expect(result_event.startStatus).to eq Event::UPCOMING
      end
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
      create_list(:event, rand(1..3), :with_market, :live,
                  title: title, event_scopes: [tournament])
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
    let(:limit) { Event::UPCOMING_DURATION }
    let(:query) do
      %({ events(context: #{upcoming_ctx}) { id } })
    end
    let!(:future_events) do
      create_list(:event, rand(1..3), :with_market, :upcoming,
                  start_at: limit.hours.from_now + 1.minute,
                  title: title,
                  event_scopes: [tournament])
    end
    let!(:live_events) do
      create_list(:event, rand(1..3), :live,
                  title: title, event_scopes: [tournament])
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
    let(:control_event) {}
    let(:limit) { Event::UPCOMING_LIMIT }
    let(:query) do
      %({ events(context: #{upcoming_limited_ctx}) { id } })
    end

    let(:first_tournament) { create(:event_scope, :tournament) }
    let!(:first_tournament_events) do
      create_list(:event, limit + rand(2..4), :with_market, :upcoming,
                  event_scopes: [first_tournament])
    end

    let(:second_tournament) { create(:event_scope, :tournament) }
    let!(:second_tournament_events) do
      create_list(:event, limit + rand(1..4), :with_market, :upcoming,
                  event_scopes: [second_tournament])
    end

    let(:live_tournament) { create(:event_scope, :tournament) }
    let!(:live_events) do
      create_list(:event, rand(1..4), :with_market, :live,
                  event_scopes: [live_tournament])
    end

    let(:tournament_event_ids) do
      first_tournament_events
        .sort_by { |event| [event.priority, event.start_at] }
        .map(&:id)
    end

    let(:included_event_ids) { tournament_event_ids.take(limit) }
    let(:truncated_event_ids) { tournament_event_ids.drop(limit) }

    before do
      control_events.each do |event|
        event.event_scopes = []
        event.save!
      end
    end

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
    let(:control_event) {}
    let(:limit) { Event::UPCOMING_LIMIT }
    let(:duration_limit) { Event::UPCOMING_DURATION }
    let(:query) do
      %({ events(context: #{upcoming_unlimited_ctx}) { id } })
    end

    let!(:tournament_events) do
      create_list(:event, limit + rand(3..5), :with_market, :upcoming,
                  tournament: tournament)
    end

    let!(:future_events) do
      create_list(:event, rand(1..4), :with_market, :upcoming,
                  start_at: duration_limit.hours.from_now + 1.week)
    end

    let!(:live_events) do
      create_list(:event, rand(1..4), :with_market, :live)
    end

    let(:upcoming_events) do
      [control_events, tournament_events].flatten
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
