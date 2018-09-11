describe 'GraphQL#title' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  describe 'query' do
    context 'basic query' do
      let(:title) { create(:title) }
      let(:query) { %({ title (id: "#{title.id}") { id name } }) }

      it 'returns a title by id' do
        expect(result['data']['title']).not_to be_nil
        expect(result['data']['title']['id']).to eq(title.id.to_s)
      end
    end

    context 'no title' do
      let(:query) { %({ title (id: "1000") { id name } }) }

      it 'returns null' do
        expect(result['data']['title']).to be_nil
      end
    end
  end
end
