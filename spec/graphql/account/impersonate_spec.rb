# frozen_string_literal: true

describe GraphQL, '#impersonate' do
  let!(:admin) { create(:user) }
  let!(:customer) { create(:customer) }
  let!(:fiat_wallet) { create(:wallet, :fiat, customer: customer) }
  let!(:crypto_wallet) { create(:wallet, :crypto, customer: customer) }
  let(:jwt_payload) do
    {
      id: customer.id,
      username: customer.username,
      email: customer.email,
      impersonated_by: admin.id
    }
  end
  let(:token) { JwtService.encode(jwt_payload) }
  let(:ip_address) { Faker::Internet.ip_v4_address }
  let(:request_mock) { OpenStruct.new(remote_ip: ip_address) }

  let(:context) { { request: request_mock } }
  let(:variables) { { token: token } }
  let(:query) do
    %(mutation ($token: String!) {
        impersonate (token: $token) {
          user {
            id
            email
            username
            wallets {
              id
              amount
              currency { id kind code }
            }
          }
          token
        }
    })
  end
  let(:result) do
    ArcanebetSchema.execute(query, context: context, variables: variables)
  end

  let(:response) { result.dig('data', 'impersonate') }

  let(:log_payload) do
    {
      message: 'Impersonation attempt with malformed token!',
      token: token,
      ip_address: ip_address,
      error_object: kind_of(ActiveRecord::RecordNotFound)
    }
  end

  before { allow(Devise).to receive(:secret_key).and_return('secret-key') }

  context 'with wrong token' do
    let(:token) { 'invalid-token' }

    it 'returns technical error' do
      expect(result['errors'].first['message'])
        .to eq(I18n.t('account.impersonate.failure'))
    end

    it 'logs malformed impersonation attempt' do
      expect(Rails.logger).to receive(:error).with(log_payload)
      result
    end
  end

  context 'with manually encrypted token' do
    let(:token) { JWT.encode(jwt_payload, '228') }

    it 'returns technical error' do
      expect(result['errors'].first['message'])
        .to eq(I18n.t('account.impersonate.failure'))
    end

    it 'logs malformed impersonation attempt' do
      expect(Rails.logger).to receive(:error).with(log_payload)
      result
    end
  end

  context 'with valid customer jwt token' do
    it 'returns token back' do
      expect(response['token']).to eq(token)
    end

    context 'with user' do
      let(:user_response) { response['user'] }
      let(:expected_wallet_ids) do
        user_response['wallets'].map { |wallet| wallet['id'].to_i }
      end

      it 'contains fields' do
        expect(user_response).to include(
          'id' => customer.id.to_s,
          'email' => customer.email,
          'username' => customer.username
        )
      end

      it 'contains wallets' do
        expect(expected_wallet_ids)
          .to match_array([fiat_wallet.id, crypto_wallet.id])
      end

      context 'with wallet' do
        let(:wallet_response) { user_response['wallets'].first }
        let(:wallet) { customer.wallets.first }
        let(:currency) { wallet.currency }

        it 'contains fields' do
          expect(wallet_response).to include(
            'id' => wallet.id.to_s,
            'amount' => wallet.amount.to_f
          )
        end

        context 'with currency' do
          let(:currency_response) { wallet_response['currency'] }

          it 'contains fields' do
            expect(currency_response).to include(
              'id' => currency.id.to_s,
              'kind' => currency.kind,
              'code' => currency.code
            )
          end
        end
      end
    end
  end
end
