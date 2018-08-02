describe 'GraphQL#placeBet' do
  let(:auth_customer) { create(:customer) }
  let(:context) { { current_customer: auth_customer } }

  let(:query) do
    %(mutation placeBets($bets: [BetInput]) {
        placeBets(bets: $bets) {
          amount
          market {
            id
            name
          }
          odd {
            id
            name
          }
        }
      })
  end

  context 'success' do
    let(:odds) { create_list(:odd, 2) }

    let(:variables) do
      {
        bets: odds.map { |odd| { amount: 10, oddId: odd.id } }
      }
    end

    let(:response) do
      ArcanebetSchema.execute(query, context: context, variables: variables)
    end

    let(:bets) { response['data']['placeBets'] }

    it 'returns an array' do
      expect(bets).to be_an Array
    end

    it 'array elements are bets' do
      bets.each do |bet|
        expect(bet['amount']).to be_a Numeric

        expect(bet['market']).to be_a Hash
        expect(bet['market']['id']).to be_a String
        expect(bet['market']['name']).to be_a String

        expect(bet['odd']).to be_a Hash
        expect(bet['odd']['id']).to be_a String
        expect(bet['odd']['name']).to be_a String
      end
    end
  end

  context 'errors' do
    it 'doesn\'t find the odd' do
      variables = { bets: [{ amount: 10, oddId: 1 }] }

      response = ArcanebetSchema.execute(
        query,
        context: context,
        variables: variables
      )

      expect(response['errors'].first['message'])
        .to eq 'Couldn\'t find Odd with \'id\'=1'
    end
  end
end
