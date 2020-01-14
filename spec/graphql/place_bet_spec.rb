# frozen_string_literal: true

describe GraphQL, '#place_bet' do
  let!(:currency) { create(:currency, :primary) }

  let(:auth_customer) { create(:customer) }
  let!(:wallet) do
    create(:wallet, :brick, customer: auth_customer, currency: currency,
                            real_money_balance: 100, bonus_balance: 100)
  end
  let(:request) do
    OpenStruct.new(remote_ip: Faker::Internet.ip_v4_address)
  end
  let(:context) { { current_customer: auth_customer, request: request } }

  let!(:live_producer) { create(:liveodds_producer) }
  let!(:prematch_producer) { create(:prematch_producer) }

  let(:query) do
    %(mutation placeBets($bets: [BetInput]) {
      placeBets(bets: $bets) {
        message
        success
        oddId
        bet {
          id
          amount
          betLegs {
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
            odds: [
              {
                id: odd.id.to_s,
                value: odd.value
              }
            ]
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

        bet['betLegs'].each do |leg|
          expect(leg['market']).to be_a Hash
          expect(leg['market']['id']).to be_a String
          expect(leg['market']['name']).to be_a String

          expect(leg['odd']).to be_a Hash
          expect(leg['odd']['id']).to be_a String
          expect(leg['odd']['name']).to be_a String
        end
      end
    end
  end

  context 'errors' do
    let(:placeBets) { response['data']['placeBets'] }
    let(:error_message) { placeBets.first['message'] }
    let(:odd) { instance_double(Odd, id: 1, value: 1.85) }
    let(:bet_currency) { currency }
    let(:variables) do
      {
        bets: [{
          amount: 10,
          currencyCode: bet_currency.code,
          odds: [
            {
              id: odd.id.to_s,
              value: odd.value
            }
          ]
        }]
      }
    end

    before { wallet.update_attributes(currency: currency) }

    it 'does not find not-existing odd and gives an error' do
      expect(error_message)
        .to eq I18n.t('bets.notifications.placement_error')
    end

    it 'returns odd id for problem bet' do
      expect(placeBets.first['oddId']).to eq(odd.id.to_s)
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
        currencyCode: currency.code,
        odds: [
          {
            id: odd.id.to_s,
            value: odd.value
          }
        ]
      }
    end

    let(:invalid_bet_attrs) do
      {
        amount: 0,
        currencyCode: 'TEST CURRENCY',
        odds: [
          {
            id: odd.id.to_s,
            value: odd.value
          }
        ]
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
          odds: [
            {
              id: odd.id.to_s,
              value: odd.value
            }
          ]
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

  context 'bonus' do
    let(:bonus_wallet) { wallet }
    let(:bonus_status) { CustomerBonus::ACTIVE }
    let(:sportsbook) { true }
    let!(:customer_bonus) do
      create(:customer_bonus, customer: auth_customer,
                              status: bonus_status,
                              sportsbook: sportsbook,
                              wallet: bonus_wallet)
    end

    let(:odd) { create(:odd, :active) }
    let(:variables) do
      {
        bets: [{
          amount: 10,
          currencyCode: currency.code,
          odds: [{
            id: odd.id.to_s,
            value: odd.value
          }]
        }]
      }
    end

    let(:created_bet) { BetLeg.find_by(odd: odd)&.bet }

    before { response }

    it 'is assigned, when active sportsbook bonus for the same wallet' do
      expect(created_bet.customer_bonus).to eq(customer_bonus)
    end

    context 'when there is no bonus' do
      let(:customer_bonus) {}

      it 'nothing is assigned' do
        expect(created_bet.customer_bonus).to be_nil
      end
    end

    context 'when bonus is inactive' do
      let(:bonus_status) { CustomerBonus::EXPIRED }

      it 'is not assigned' do
        expect(created_bet.customer_bonus).to be_nil
      end
    end

    context 'when bonus is not sportsbook' do
      let(:sportsbook) { false }

      it 'is not assigned' do
        expect(created_bet.customer_bonus).to be_nil
      end
    end

    context 'when bonus is for another wallet' do
      let!(:bonus_wallet) do
        create(:wallet, :brick,
               customer: auth_customer,
               currency: create(:currency, :crypto),
               real_money_balance: 100,
               bonus_balance: 0)
      end

      it 'is not assigned' do
        expect(created_bet.customer_bonus).to be_nil
      end
    end
  end
end
