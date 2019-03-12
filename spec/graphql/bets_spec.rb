describe GraphQL, '#bets' do
  let!(:auth_customer) { create(:customer) }
  let(:context) { { current_customer: auth_customer } }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  context 'basic query' do
    let!(:bets) { create_list(:bet, 5, customer: auth_customer) }
    let(:bet) { bets.sort_by(&:created_at).reverse.first }
    let(:query) do
      %({
        bets {
          pagination {
            count
            items
            page
            pages
            offset
            last
            next
            prev
            from
            to
          }
          collection {
            id
            created_at
          }
        }
      })
    end

    it 'returns bets' do
      expect(result['data']['bets']['collection'][0]['id']).to eq(bet.id.to_s)
    end

    it 'includes pagination param - items' do
      expect(result['data']['bets']['pagination']['items'])
        .to eq(bets.length)
    end
  end
end
