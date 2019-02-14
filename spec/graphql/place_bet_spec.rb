# frozen_string_literal: true

describe GraphQL, '#place_bet' do
  let!(:currency) { create(:currency, code: 'EUR') }
  let(:auth_customer) { create(:customer) }
  let(:wallet) do
    create(:wallet, :brick, customer: auth_customer, currency: currency)
  end
  let(:context) { { current_customer: auth_customer } }

  let!(:live_producer) { create(:liveodds_producer) }
  let!(:prematch_producer) { create(:prematch_producer) }

  let(:query) do
    %(mutation placeBets($bets: [BetInput]) {
        placeBets(bets: $bets) {
            id
            message
            success
            bet {
                 id
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
        }
      })
  end

  let(:response) do
    ArcanebetSchema.execute(query, context: context, variables: variables)
  end

  context 'success' do
    let(:odds) { create_list(:odd, 2, :active, value: 8.87) }
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

    it 'returns success' do
      expect(bets.first['success']).to be_truthy
    end

    it 'array elements are bets' do
      bets.map { |bet_response| bet_response['bet'] }.each do |bet|
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
    let(:odd) { create(:odd, :active, value: 8.87) }
    let(:bonus_balance_amount) { 250 }
    let(:real_amount) { 750 }
    let(:bet_amount) { 10 }
    let!(:active_bonus) do
      create(:customer_bonus,
             customer: auth_customer,
             wallet: wallet,
             entry: create(:entry),
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
        kind: EntryKinds::BET,
        max_amount: 0,
        min_amount: -100
      )
    end

    it 'creates balance entry requests for real and bonus balances' do
      execute_query
      kinds = BalanceEntryRequest.pluck(:kind)

      expect(kinds).to match_array([Balance::REAL_MONEY, Balance::BONUS])
    end

    it 'places bet with system mode' do
      execute_query

      expect(EntryRequest.pluck(:mode).uniq).to eq([EntryRequest::SYSTEM])
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
      expect(response['data']['placeBets'].first['message'])
        .to include 'Couldn\'t find Odd with \'id\'=1'
    end

    it 'doesn\'t find the currency' do
      odd = create(:odd, :active)

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

      expect(response['data']['placeBets'].first['message'])
        .to eq 'Couldn\'t find Currency'
    end
  end

  context 'multiple bets handling' do
    let(:odd) { create(:odd, :active, value: 8.87) }

    let(:valid_bet_attrs) do
      {
        amount: 10,
        currencyCode: 'EUR',
        oddId: odd.id.to_s,
        oddValue: odd.value
      }
    end

    let(:invalid_bet_attrs) do
      {
        amount: 0,
        currencyCode: 'TEST CURRENCY',
        oddId: odd.id.to_s,
        oddValue: odd.value
      }
    end

    let(:variables) do
      {
        bets: [invalid_bet_attrs, valid_bet_attrs]
      }
    end

    let(:succeeded_bets_response) do
      response['data']['placeBets'].select { |bet| bet['success'] }
    end

    let(:failed_bets_response) do
      response['data']['placeBets'].reject { |bet| bet['success'] }
    end

    it 'returns correct count of succeeded responses' do
      expect(succeeded_bets_response.count).to eq(1)
    end

    it 'returns correct count of failed responses' do
      expect(failed_bets_response.count).to eq(1)
    end

    it 'succeeded response includes placed bet' do
      expect(succeeded_bets_response.first['bet']).not_to be_nil
    end

    context 'with predictably invalid bet on internal validation' do
      let(:invalid_bet_attrs) do
        {
          amount: 0,
          currencyCode: 'EUR',
          oddId: odd.id.to_s,
          oddValue: odd.value
        }
      end

      let(:variables) do
        { bets: [invalid_bet_attrs] }
      end

      it 'recognizes it as success for GraphQL response' do
        expect(succeeded_bets_response.count).to eq(1)
      end
    end
  end
end
