describe GraphQL, '#createEveryMatrixSession' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:response) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end
  let(:query) do
    %(mutation createEveryMatrixSession($walletId: Int!) {
        createEveryMatrixSession(walletId: $walletId) {
          sessionId
        }
      })
  end

  context 'with authenticated customer' do
    let(:auth_customer) { create(:customer, :ready_to_bet) }
    let(:context) { { current_customer: auth_customer } }

    context 'with own walletId' do
      let(:variables) { { walletId: auth_customer.wallet.id } }

      it 'resonds with session id' do
        expect(
          response['data']['createEveryMatrixSession']['sessionId']
        ).not_to be_nil
      end
    end

    context 'with someone else\'s wallet' do
      let(:other_customer) { create(:customer, :ready_to_bet) }
      let(:variables) { { walletId: other_customer.wallet.id } }

      it 'resonds with error' do
        expect(response['errors']).not_to be_empty
      end
    end
  end

  context 'without authenticated customer' do
    let(:other_customer) { create(:customer, :ready_to_bet) }
    let(:variables) { { walletId: other_customer.wallet.id } }

    it 'resonds with error' do
      expect(response['errors']).not_to be_empty
    end
  end
end
