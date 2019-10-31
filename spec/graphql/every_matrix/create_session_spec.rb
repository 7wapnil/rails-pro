# frozen_string_literal: true

describe GraphQL, '#createEveryMatrixSession' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:response) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end
  let(:query) do
    %(mutation createEveryMatrixSession($walletId: Int, $playItemId: String!) {
        createEveryMatrixSession(walletId: $walletId, playItemId: $playItemId) {
          launchUrl
        }
      })
  end
  let(:game) { create(:casino_game) }
  let(:base_launch_url) { game.url }

  context 'with authenticated customer' do
    let(:auth_customer) { create(:customer, :ready_to_bet) }
    let(:context) { { current_customer: auth_customer } }
    let(:token) do
      EveryMatrix::WalletSession
        .where(wallet_id: auth_customer.wallet.id)
        .last
        .id
    end

    context 'with own walletId' do
      let(:variables) do
        {
          walletId: auth_customer.wallet.id,
          playItemId: game.id
        }
      end

      it 'responds with launch url' do
        expect(response['data']['createEveryMatrixSession']['launchUrl'])
          .to eq(
            "#{base_launch_url}?language=en&funMode=False&_sid=#{token}"
          )
      end
    end

    context 'with someone else\'s wallet' do
      let(:other_customer) { create(:customer, :ready_to_bet) }
      let(:variables) do
        {
          walletId: other_customer.wallet.id,
          playItemId: game.id
        }
      end

      it 'responds with error' do
        expect(response['errors']).not_to be_empty
      end
    end
  end

  context 'without authenticated customer' do
    let(:other_customer) { create(:customer, :ready_to_bet) }
    let(:variables) { { playItemId: game.id } }

    it 'responds base launch url' do
      expect(response['data']['createEveryMatrixSession']['launchUrl'])
        .to eq(base_launch_url)
    end
  end
end
