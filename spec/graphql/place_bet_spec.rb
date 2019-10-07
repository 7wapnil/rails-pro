# frozen_string_literal: true

describe GraphQL, '#place_bet' do
  let!(:currency) { create(:currency, code: 'EUR') }
  let(:auth_customer) { create(:customer) }
  let!(:wallet) do
    create(:wallet, :brick, customer: auth_customer, currency: currency,
                            real_money_balance: 100, bonus_balance: 100)
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

  context 'errors' do
    let(:error_message) { response['data']['placeBets'].first['message'] }
    let(:odd) { instance_double(Odd, id: 1, value: 1.85) }
    let(:bet_currency) { currency }
    let(:variables) do
      {
        bets: [{
          amount: 10,
          currencyCode: bet_currency.code,
          oddId: odd.id.to_s,
          oddValue: odd.value
        }]
      }
    end

    before { wallet.update_attributes(currency: currency) }

    it 'does not find not-existing odd and gives an error' do
      expect(error_message)
        .to eq I18n.t('bets.notifications.placement_error')
    end

    context 'with inactive odd' do
      let!(:odd) { create(:odd) }

      it 'gives an error' do
        expect(error_message)
          .to eq I18n.t('bets.notifications.placement_error')
      end
    end

    context 'with negative real money balance' do
      let!(:wallet) do
        create(:wallet, :brick, customer: auth_customer, currency: currency,
                                real_money_balance: -10, bonus_balance: 100)
      end

      it 'gives an error' do
        expect(error_message)
          .to eq I18n.t('bets.notifications.placement_error')
      end
    end

    context 'with negative bonus balance' do
      let!(:wallet) do
        create(:wallet, :brick, customer: auth_customer, currency: currency,
                                real_money_balance: 100, bonus_balance: -10)
      end

      it 'gives an error' do
        expect(error_message)
          .to eq I18n.t('bets.notifications.placement_error')
      end
    end

    context 'when currency does not exists' do
      let!(:odd) { create(:odd, :active) }
      let(:bet_currency) { instance_double(Currency, code: 'ZZZ') }

      it 'gives an error' do
        expect(error_message)
          .to eq I18n.t('bets.notifications.placement_error')
      end
    end
  end

  context 'multiple bets handling' do
    let(:market) { create(:market) }
    let(:odd) { create(:odd, :active, value: 8.87, market: market) }

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

    context 'with suspended market' do
      let(:market) { create(:market, :suspended) }
      let(:variables) { { bets: [valid_bet_attrs] } }

      it 'recognizes it as failure for GraphQL response' do
        expect(failed_bets_response.count).to eq(1)
      end
    end

    context 'with inactive odd' do
      let(:odd) { create(:odd, :inactive, value: 8.87) }
      let(:variables) { { bets: [valid_bet_attrs] } }

      it 'recognizes it as failure for GraphQL response' do
        expect(failed_bets_response.count).to eq(1)
      end
    end
  end
end
