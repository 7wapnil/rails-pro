describe 'GraphQL#events' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  describe 'query' do
    context 'basic query' do
      before do
        create_list(:event, 5)
      end

      let(:query) { %({ events { id name } }) }

      it 'returns list of events' do
        expect(result['data']['events'].count).to eq(5)
      end
    end

    context 'with markets' do
      let!(:event) { create(:event) }
      let!(:market) do
        create(:market, event: event, status: Market::DEFAULT_STATUS)
      end
      let(:query) do
        %({
            events {
              id
              name
              markets { id name priority status }
            }
        })
      end

      it 'returns event markets list' do
        event_result = result['data']['events'][0]
        expect(event_result['markets'].count).to eq(1)
        expect(event_result['markets'][0]['id']).to eq(market.id.to_s)
        expect(event_result['markets'][0]['name']).to eq(market.name)
        expect(event_result['markets'][0]['status']).to eq('active')
      end
    end

    context 'with odds' do
      let!(:event) { create(:event) }
      let!(:market) { create(:market, event: event) }
      let!(:odd) do
        create(:odd, market: market, status: Odd.statuses[:active])
      end
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

      it 'returns event market odds list' do
        odd_result = result['data']['events'][0]['markets'][0]['odds']
        expect(odd_result.count).to eq(1)
        expect(odd_result[0]['id']).to eq(odd.id.to_s)
        expect(odd_result[0]['name']).to eq(odd.name)
        expect(odd_result[0]['status']).to eq('active')
      end
    end
  end
end
