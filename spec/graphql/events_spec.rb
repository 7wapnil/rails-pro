describe 'GraphQL#events' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  describe 'query' do
    before do
      title = create(:title)
      create_list(:event, 5, title: title)
    end

    let(:query) { %({ events { id name } }) }

    it 'returns list of events' do
      expect(result['data']['events'].count).to eq(5)
    end
  end
end
