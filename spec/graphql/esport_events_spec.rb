# frozen_string_literal: true

describe GraphQL, '#esportEvents' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:upcoming_ctx) { 'upcoming' }
  let(:live_ctx) { 'live' }

  let(:result) do
    ArcanebetSchema.execute(query, context: context, variables: variables)
  end

  let(:title) { create(:title, name: 'Counter-Strike', kind: Title::ESPORTS) }
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

  let(:result_events) { result&.dig('data', 'esportEvents') }
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
    let(:query) do
      %({
          esportEvents(context: #{upcoming_ctx}, titleId: #{title.id}) { id }
      })
    end

    before { create_list(:event, 3, :upcoming, visible: false, title: title) }

    it 'returns valid esportEvents' do
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
          esportEvents(titleId: #{title.id}, context: #{upcoming_ctx}) {
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
        %({
          esportEvents(titleId: #{title.id}, context: #{upcoming_ctx}) {
            id
            marketsCount
          }
        })
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
          esportEvents(titleId: #{title.id}, context: #{upcoming_ctx}) {
            id
            dashboardMarket {
              id
              odds { id }
            }
          }
      })
    end

    it 'does not return esportEvents' do
      expect(result_events).to be_empty
    end
  end

  context 'with categories' do
    let(:query) do
      %({
          esportEvents(titleId: #{title.id}, context: #{upcoming_ctx}) {
            id
            categories { id name count }
          }
      })
    end

    let(:players_template) do
      create(:market_template, category: MarketTemplate::PLAYERS)
    end
    let(:template_without_category) { create(:market_template, category: nil) }
    let(:event) { result['data']['esportEvents'][0] }
    let(:categories) do
      event['categories'].sort_by { |category| category['name'] }
    end

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

    it 'check category length' do
      expect(categories.length).to eq(2)
    end

    it 'check id for first category' do
      expect(categories[0]['id'])
        .to eq("#{event['id']}:#{MarketTemplate::PLAYERS}")
    end

    it 'check count of events for first category' do
      expect(categories[0]['count']).to eq(2)
    end

    it 'check id for second category' do
      expect(categories[1]['id'])
        .to eq("#{event['id']}:#{MarketTemplate::POPULAR}")
    end

    it 'check count of events for second category' do
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
          esportEvents(titleId: #{title.id}, context: #{upcoming_ctx}) {
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
               event_scopes: [tournament], title: title),
        create(:event, :with_market, :upcoming,
               priority: Event::PRIORITIES.first,
               event_scopes: [tournament], title: title),
        create(:event, :with_market, :upcoming,
               priority: Event::PRIORITIES.third,
               event_scopes: [tournament], title: title)
      ]
    end

    let(:sorted_events) { control_events.sort_by(&:priority) }

    let(:query) do
      %({
      esportEvents(titleId: #{title.id}, context: #{upcoming_ctx}){
        id
        priority
      }
    })
    end

    it 'returns esportEvents in valid order' do
      expect(result_event_ids).to eq(sorted_events.map(&:id))
    end
  end

  context 'start status' do
    let(:query) do
      %({
      esportEvents(titleId: #{title.id}, context: #{ctx}) { id startStatus }
    })
    end
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
      let(:ctx) { 'upcoming' }
      let(:control_event_traits) { %i[with_market upcoming] }

      it 'value is UPCOMING' do
        expect(result_event.startStatus).to eq Event::UPCOMING
      end
    end
  end

  context 'with invalid context' do
    let(:query) do
      %({ esportEvents(context: abcd) {
          id
          live
    } })
    end

    it 'when context is unsupported raises an error' do
      expect(result['errors']).not_to be_empty
    end

    it 'without context raises an error' do
      query = %({ esportEvents(titleId: #{title.id}){ id } })

      result = ArcanebetSchema.execute(query,
                                       context: context,
                                       variables: variables)
      error_msg = I18n.t(
        'errors.messages.graphql.events.context.invalid',
        context: nil,
        contexts: Events::BySport::EsportQueryResolver::SUPPORTED_CONTEXTS
          .join(', ')
      )

      expect(result['errors'].first['message']).to eq(error_msg)
    end
  end

  context 'with invalid titleId' do
    let(:query) do
      %({ esportEvents(context: #{upcoming_ctx}) {
          id
          live
    } })
    end

    it 'when titleId is blank raises an error' do
      expect(result['errors']).not_to be_empty
    end

    it 'with invalid titleId is blank array' do
      query = %({ esportEvents(titleId: 0, context: #{upcoming_ctx}){ id } })

      ArcanebetSchema.execute(query,
                              context: context,
                              variables: variables)

      expect(result_events.to_a).to match_array([])
    end
  end

  it 'context cannot be omitted even when title id is present' do
    create(:event_scope, :with_event)
    query = %({ esportEvents(titleId: #{title.id}) { id } })

    result = ArcanebetSchema.execute(query,
                                     context: context,
                                     variables: variables)

    error_msg = I18n.t(
      'errors.messages.graphql.events.context.invalid',
      context: nil,
      contexts: Events::BySport::EsportQueryResolver::SUPPORTED_CONTEXTS
        .join(', ')
    )

    expect(result['errors'].first['message']).to eq(error_msg)
  end

  context "with 'live' context" do
    let(:query) do
      %({ esportEvents(titleId: #{title.id}, context: #{live_ctx}) { id } })
    end
    let!(:live_events) do
      create_list(:event, rand(1..3), :with_market, :live,
                  title: title, event_scopes: [tournament])
    end

    it 'ignores upcoming esportEvents' do
      expect(result_event_ids).not_to include(*control_events.map(&:id))
    end

    it 'returns live esportEvents' do
      expect(result_event_ids).to match_array(live_events.map(&:id))
    end
  end
end
