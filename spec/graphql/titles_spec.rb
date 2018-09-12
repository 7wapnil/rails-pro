describe 'GraphQL#titles' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  describe 'query' do
    context 'basic query' do
      let(:query) { %({ titles { id name } }) }
      before do
        create_list(:title, 5)
      end

      it 'returns list of titles' do
        expect(result['data']['titles'].count).to eq(5)
      end
    end

    context 'with kind' do
      let(:query) do
        %({
            titles (kind: "esports") {
              id
              name
              kind
            }
        })
      end

      before do
        create_list(:title, 5, kind: :sports)
        create_list(:title, 5, kind: :esports)
      end

      it 'returns esports titles list' do
        expect(result['data']['titles'].count).to eq(5)
      end
    end
  end
end
