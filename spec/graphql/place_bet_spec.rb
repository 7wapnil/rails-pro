describe GraphQL, '#place_bet' do
  let!(:currency) { create(:currency, code: 'EUR') }
  let(:auth_customer) { create(:customer) }
  let(:wallet) do
    create(:wallet, :brick, customer: auth_customer, currency: currency)
  end
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
    let(:odds) { create_list(:odd, 2, value: 8.87) }
    let(:variables) do
      {
        bets: odds.map do |odd|
          {
            amount: 10,
            currencyCode: 'EUR',
            oddId: odd.id.to_s,
            oddValue: odd.value
          }
        end
      }
    end

    let(:response) do
      ArcanebetSchema.execute(query, context: context, variables: variables)
    end

    let(:bets) { response['data']['placeBets'] }

    before do
      create(:balance, kind: :bonus, wallet: wallet, amount: 100)
      create(:balance, wallet: wallet, amount: 200)
      create(
        :entry_currency_rule,
        currency: currency,
        kind: EntryRequest.kinds[:bet],
        max_amount: 0,
        min_amount: -100
      )
    end

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

  context 'bonus applying' do
    let(:odd) { create(:odd, value: 8.87) }
    let(:bonus_balance_amount) { 250 }
    let(:real_amount) { 750 }
    let(:bet_amount) { 10 }
    let!(:active_bonus) do
      create(:customer_bonus,
             customer: auth_customer,
             wallet: wallet,
             rollover_balance: 10,
             percentage: 25)
    end
    let(:variables) do
      {
        bets: [
          {
            amount: bet_amount,
            currencyCode: 'EUR',
            oddId: odd.id.to_s,
            oddValue: odd.value
          }
        ]
      }
    end

    let(:execute_query) do
      ArcanebetSchema.execute(
        query,
        context: context,
        variables: variables
      )
    end

    before do
      create(:entry_currency_rule,
             currency: currency,
             min_amount: 10,
             max_amount: 100)
      create(:balance,
             kind: :bonus,
             wallet: wallet,
             amount: bonus_balance_amount)
      create(:balance,
             wallet: wallet,
             amount: real_amount)
      create(
        :entry_currency_rule,
        currency: currency,
        kind: EntryRequest.kinds[:bet],
        max_amount: 0,
        min_amount: -100
      )
    end

    it 'charges real and bonus balances for customer with bonus' do
      execute_query
      expected_bonus_balance = 247.5
      expected_real_balance = 742.5

      expect(wallet.bonus_balance.amount).to eq(expected_bonus_balance)
      expect(wallet.real_money_balance.amount).to eq(expected_real_balance)
    end

    it 'charge only real money balance' do
      auth_customer.customer_bonus.destroy
      auth_customer.reload
      execute_query
      expected_real_balance = real_amount - bet_amount

      expect(wallet.real_money_balance.amount).to eq(expected_real_balance)
      expect(wallet.bonus_balance.amount).to eq(bonus_balance_amount)
    end

    it 'do not apply bonus when odd value is less than allowed' do
      active_bonus.update_attributes(min_odds_per_bet: odd.value + 1.0)
      execute_query

      expect(wallet.bonus_balance.amount).to eq(bonus_balance_amount)
    end
    it 'creates balance entry requests for real and bonus balances' do
      execute_query
      kinds = BalanceEntryRequest.pluck(:kind)

      expect(kinds).to match_array([Balance::REAL_MONEY, Balance::BONUS])
    end

    context 'when customer with bonus' do
      before do
        execute_query
      end

      it_behaves_like 'entries splitting with bonus' do
        let(:real_money_amount) { -7.5 }
        let(:bonus_amount) { -2.5 }
      end
    end

    context 'when customer without bonus' do
      before do
        auth_customer.customer_bonus.destroy
        auth_customer.reload
        execute_query
      end

      it_behaves_like 'entries splitting without bonus' do
        let(:real_money_amount) { -bet_amount }
      end
    end
  end

  context 'errors' do
    before do
      wallet.update_attributes(currency: currency)
    end

    it 'doesn\'t find the odd' do
      variables = {
        bets: [
          { amount: 10, currencyCode: 'EUR', oddId: '1', oddValue: 1.85 }
        ]
      }

      response = ArcanebetSchema.execute(
        query,
        context: context,
        variables: variables
      )

      expect(response['errors'].first['message'])
        .to eq 'Couldn\'t find Odd with \'id\'=1'
    end

    it 'doesn\'t find the currency' do
      odd = create(:odd)

      variables = {
        bets: [
          {
            amount: 10, currencyCode: 'ZZZ', oddId: odd.id.to_s, oddValue: 1.85
          }
        ]
      }

      response = ArcanebetSchema.execute(
        query,
        context: context,
        variables: variables
      )

      expect(response['errors'].first['message'])
        .to eq 'Couldn\'t find Currency'
    end
  end
end
