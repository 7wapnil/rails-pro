describe 'GraphQL#events' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  let(:title) { create(:title, name: 'Counter-Strike') }

  describe 'query' do
    context 'basic query' do
      before do
        create_list(:event_with_odds, 5, title: title)
      end

      let(:query) { %({ events { id name } }) }

      it 'returns list of events' do
        expect(result['data']['events'].count).to eq(5)
      end
    end

    context 'with markets' do
      let!(:event) { create(:event_with_odds, title: title) }
      let(:query) do
        %({
            events {
              id
              name
              markets { id name priority status }
            }
        })
      end

      before do
        event.markets.update_all(status: Market::DEFAULT_STATUS)
      end

      it 'returns event markets list' do
        market = event.markets[0]
        event_result = result['data']['events'][0]
        expect(event_result['markets'].count).to eq(1)
        expect(event_result['markets'][0]['id']).to eq(market.id.to_s)
        expect(event_result['markets'][0]['name']).to eq(market.name)
        expect(event_result['markets'][0]['status']).to eq('active')
      end
    end

    context 'with markets priority' do
      let(:query) do
        %({
            events {
              id
              name
              markets (priority: 1) { id name priority status }
            }
        })
      end

      before do
        event = create(:event_with_odds, title: title)
        allow_any_instance_of(Market).to receive(:define_priority)
        event.markets.update_all(status: Market::DEFAULT_STATUS,
                                 priority: 0)

        create(:market,
               :with_odds,
               event: event,
               status: Market::DEFAULT_STATUS,
               priority: 1)
      end

      it 'returns event markets list with priority 1' do
        event_result = result['data']['events'][0]
        expect(event_result['markets'].count).to eq(1)
      end
    end

    context 'with odds' do
      let!(:event) { create(:event_with_odds, title: title) }
      let(:query) do
        %({
            events {
              id
              name
              markets {
                id
                odds { id name status }
              }
            }
        })
      end

      before do
        Odd.update_all(status: Odd.statuses[:active])
      end

      it 'returns event market odds list' do
        odd_result = result['data']['events'][0]['markets'][0]['odds']
        expect(odd_result.count).to be > 0
      end
    end

    context 'without odds' do
      let(:query) { %({ events { id name } }) }

      before do
        create_list(:event_with_market, 5, title: title)
      end

      it 'returns empty list when no odds' do
        expect(result['data']['events'].count).to eq(0)
      end
    end

    context 'limited result' do
      let(:limit) { 3 }
      let(:query) do
        %({ events (
              limit: #{limit}
          ) {
              id
        } })
      end

      before do
        create_list(:event_with_odds, 5, title: title)
      end

      it 'returns limited events' do
        expect(result['data']['events'].count).to eq(3)
      end
    end

    context 'single event' do
      let(:event) { create(:event_with_odds) }
      let(:query) do
        %({ events (
              filter: { id: #{event.id} }
          ) {
              id
        } })
      end

      it 'returns event with defined id' do
        expect(result['data']['events'].count).to eq(1)
        expect(result['data']['events'][0]['id']).to eq(event.id.to_s)
      end
    end

    context 'in play' do
      let(:query) do
        %({ events (
              filter: { inPlay: true }
          ) {
              id
        } })
      end

      before do
        create_list(
          :event_with_odds,
          5,
          title: title,
          traded_live: true,
          start_at: 5.minutes.ago,
          end_at: nil
        )
      end

      it 'returns in play events' do
        expect(result['data']['events'].count).to eq(5)
      end
    end

    context 'title' do
      let(:query) do
        %({ events (
              filter: { titleId: #{title.id} }
          ) {
              id
        } })
      end

      before do
        other_title = create(:title)
        create_list(
          :event_with_odds,
          5,
          title: title,
          start_at: 5.minutes.ago,
          end_at: nil
        )
        create_list(
          :event_with_odds,
          5,
          title: other_title,
          start_at: 5.minutes.ago,
          end_at: nil
        )
      end

      it 'returns events by title ID' do
        expect(result['data']['events'].count).to eq(5)
      end
    end
  end
end
