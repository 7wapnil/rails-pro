describe GraphQL, '#deposit_request' do
  let(:wallet) { create(:wallet) }
  let(:bonus) { create(:bonus) }

  let(:auth_customer) { wallet.customer }
  let(:currency) { wallet.currency }
  let(:amount) { Faker::Number.decimal(2, 2) }

  let(:context) { { current_customer: auth_customer } }
  let(:variables) do
    { input: {
      amount: amount.to_s,
      currency_code: currency.code,
      bonus_code: bonus.code
    } }
  end
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  let(:gateway_url) { Faker::Internet.url }

  before do
    allow(ENV).to receive(:[])
      .with('SAFECHARGE_HOSTED_PAYMENTS_URL')
      .and_return(gateway_url)
    allow(Deposits::InitiateHostedDepositService)
      .to receive(:call) {
        create(:entry_request, status: EntryRequest::INITIAL)
      }
  end

  describe 'query' do
    let(:query) do
      %(mutation($input: DepositRequestInput!) {
        requestDeposit(input: $input){
          success
          result
          url
        }
      })
    end

    it 'builds entry request based on correct params' do
      result
      expect(Deposits::InitiateHostedDepositService)
        .to have_received(:call)
        .with(
          customer: auth_customer,
          currency: currency,
          amount: amount,
          bonus_code: bonus.code
        )
        .once
    end

    it 'returns deposit request success' do
      expect(result['data']['requestDeposit']['success']).to eq('true')
    end

    it 'returns deposit request url' do
      expect(result['data']['requestDeposit']['url']).to eq(gateway_url)
    end

    context 'when query is not successful' do
      let(:failure_msg) { Faker::Lorem.sentence(6) }

      before do
        allow(Deposits::InitiateHostedDepositService)
          .to receive(:call) {
            create(:entry_request,
                   status: EntryRequest::FAILED,
                   result: failure_msg)
          }
      end

      it 'returns deposit request success false' do
        expect(result['data']['requestDeposit']['success']).to eq('false')
      end

      it 'returns deposit request failure result' do
        expect(result['data']['requestDeposit']['result']).to eq(failure_msg)
      end
    end
  end
end
