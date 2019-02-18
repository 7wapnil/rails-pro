describe GraphQL, '#event' do
  let(:context) { {} }
  let(:variables) { {} }

  let(:result) do
    ArcanebetSchema.execute(query, context: context, variables: variables)
  end

  context 'basic query' do
    let!(:event) do
      create(:event, visible: true)
    end
    let(:query) { %({ event (id: "#{event.id}") { id } }) }

    it 'returns valid event' do
      expect(result['data']['event']['id']).to eq(event.id.to_s)
    end

    it 'returns empty result for invisible event' do
      event.update_attributes!(visible: false)
      expect(result['data']['event']).to be_nil
    end
  end
end
