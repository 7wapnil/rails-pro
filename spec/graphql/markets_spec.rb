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
        create_list(:market, 5, event: event, priority: 0)
        create_list(:market, 5, priority: 0)
        expect(result['data']['markets'].count).to eq(5)
      end

      it 'returns markets filtered by priority' do
        create_list(:market, 5, event: event, priority: 0)
        create_list(:market, 5, event: event, priority: 1)
        expect(result['data']['markets'].count).to eq(5)
      end
    end

    context 'pagination' do
      let(:query) do
        %({ markets (
              eventId: #{event.id},
              offset: #{offset},
              limit: #{limit}
          ) {
              id
        } })
      end

      before do
        create_list(:market, 5, event: event)
      end

      context 'limit' do
        let(:offset) { 0 }
        let(:limit) { 3 }

        it 'returns limited markets' do
          expect(result['data']['markets'].count).to eq(3)
        end
      end

      context 'offset' do
        let(:offset) { 4 }
        let(:limit) { nil }

        it 'returns markets with offset' do
          expect(result['data']['markets'].count).to eq(1)
        end
      end
    end
  end
end
