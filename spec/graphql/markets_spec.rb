describe 'GraphQL#markets' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end
  let(:event) { create(:event) }

  describe 'query' do
    context 'no event ID' do
      let(:query) { %({ markets { id name } }) }

      it 'returns error when no event ID defined' do
        expect(result['errors'][0]['message']).to eq('Event ID is required')
      end
    end

    context 'basic query' do
      let(:priority) { 0 }
      let(:query) do
        %({ markets (eventId: #{event.id}, priority: #{priority}) {
              id
              name
              priority
        } })
      end

      before do
        allow_any_instance_of(Market).to receive(:define_priority)
      end

      it 'returns markets related to event only' do
        create_list(:market, 5, :with_odds, event: event, priority: 0)
        create_list(:market, 5, :with_odds, priority: 0)
        expect(result['data']['markets'].count).to eq(5)
      end

      it 'returns markets filtered by priority' do
        create_list(:market, 5, :with_odds, event: event, priority: 0)
        create_list(:market, 5, :with_odds, event: event, priority: 1)
        expect(result['data']['markets'].count).to eq(5)
      end
    end

    context 'limited result' do
      let(:limit) { 3 }
      let(:query) do
        %({ markets (
              eventId: #{event.id},
              limit: #{limit}
          ) {
              id
        } })
      end

      before do
        create_list(:market, 5, :with_odds, event: event)
      end

      it 'returns limited markets' do
        expect(result['data']['markets'].count).to eq(3)
      end
    end

    context 'single market' do
      let(:market) { create(:market, :with_odds, event: event) }
      let(:query) do
        %({ markets (
              eventId: #{event.id},
              id: #{market.id}
          ) {
              id
        } })
      end

      it 'returns limited markets' do
        expect(result['data']['markets'].count).to eq(1)
        expect(result['data']['markets'][0]['id']).to eq(market.id.to_s)
      end
    end
  end
end