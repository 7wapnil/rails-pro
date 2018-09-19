describe 'GraphQL#market' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  describe 'query' do
    context 'basic query' do
      let(:query) do
        %({ market (id: #{market_id}) {
              id
        } })
      end

      context 'no market' do
        let(:market_id) { 1000 }

        it 'returns null' do
          expect(result['data']['market']).to be_nil
        end
      end

      context 'existing market' do
        let(:market) { create(:market) }
        let(:market_id) { market.id }

        it 'returns null' do
          expect(result['data']['market']).not_to be_nil
        end
      end
    end
  end
end
