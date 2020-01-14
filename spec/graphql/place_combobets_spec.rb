# frozen_string_literal: true

describe GraphQL, '#place_combo_bets' do
  let!(:currency) { create(:currency, :primary) }

  let(:auth_customer) { create(:customer) }
  let!(:wallet) do
    create(:wallet, :brick, customer: auth_customer,
                            currency: currency,
                            real_money_balance: 100,
                            bonus_balance: 100)
  end
  let(:request) do
    OpenStruct.new(remote_ip: Faker::Internet.ip_v4_address)
  end
  let(:context) { { current_customer: auth_customer, request: request } }

  let!(:live_producer) { create(:liveodds_producer) }
  let!(:prematch_producer) { create(:prematch_producer) }

  let(:query) do
    %(mutation placeComboBets($bet: BetInput) {
      placeComboBets(bet: $bet) {
        message
        success
        bet {
          id
          amount
          betLegs {
            oddId
            oddValue
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
        bet: {
          amount: 10,
          currencyCode: 'EUR',
          odds: odds.map do |odd|
            {
              id: odd.id.to_s,
              value: odd.value
            }
          end
        }
      }
    end

    let(:placement_response) { response['data']['placeComboBets'] }
    let(:bet) { placement_response['bet'] }

    before do
      create(
        :entry_currency_rule,
        currency: currency,
        kind: EntryRequest.kinds[:bet],
        max_amount: 0,
        min_amount: -100
      )
    end

    it 'returns success' do
      expect(placement_response['success']).to be_truthy
    end

    it 'returns bet' do # rubocop:disable RSpec/MultipleExpectations
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

    context 'bet leg attributes' do
      let(:odd) { odds.first }
      let(:bet_leg) { bet['betLegs'].first }

      it 'has odd id' do
        expect(bet_leg['oddId']).to eq(odd.id.to_s)
      end

      it 'has odd' do
        expect(bet_leg['odd']['id']).to eq(odd.id.to_s)
      end

      it 'has correct odd value' do
        expect(bet_leg['oddValue']).to eq(odd.value.to_f)
      end

      it 'has market id' do
        expect(bet_leg['market']['id']).to eq(odd.market.id.to_s)
      end
    end
  end

  context 'errors' do
    let(:response_data) { response['data']['placeComboBets'] }
    let(:error_message) { response_data['message'] }
    let(:fake_odd) { instance_double(Odd, id: 1, value: 1.85) }
    let(:odd) { create(:odd, :active, value: 1.5) }
    let(:bet_currency) { currency }
    let(:variables) do
      {
        bet: {
          amount: 10,
          currencyCode: bet_currency.code,
          odds: [
            {
              id: fake_odd.id.to_s,
              value: fake_odd.value
            },
            {
              id: odd.id.to_s,
              value: odd.value
            }
          ]
        }
      }
    end

    before { wallet.update_attributes(currency: currency) }

    it 'does not find not-existing odd and gives an error' do
      expect(error_message)
        .to eq I18n.t('bets.notifications.placement_error')
    end

    context 'with inactive odd' do
      let(:fake_odd) { create(:odd) }

      it 'gives an error' do
        expect(error_message)
          .to eq I18n.t('bets.notifications.placement_error')
      end
    end

    context 'with negative real money balance' do
      let(:fake_odd) { create(:odd, :active) }
      let!(:wallet) do
        create(:wallet, :brick, customer: auth_customer,
                                currency: currency,
                                real_money_balance: -10,
                                bonus_balance: 100)
      end

      it 'gives an error' do
        expect(error_message)
          .to eq I18n.t('bets.notifications.placement_error')
      end
    end

    context 'with negative bonus balance' do
      let(:fake_odd) { create(:odd, :active) }
      let!(:wallet) do
        create(:wallet, :brick, customer: auth_customer,
                                currency: currency,
                                real_money_balance: 100,
                                bonus_balance: -10)
      end

      it 'gives an error' do
        expect(error_message)
          .to eq I18n.t('bets.notifications.placement_error')
      end
    end

    context 'when currency does not exists' do
      let(:fake_odd) { create(:odd, :active) }
      let(:bet_currency) { instance_double(Currency, code: 'ZZZ') }

      it 'gives an error' do
        expect(error_message)
          .to eq I18n.t('bets.notifications.placement_error')
      end
    end

    context 'when two selections from the same event' do
      let(:market) { create(:market, event: odd.market.event) }
      let(:fake_odd) { create(:odd, :active, market: market) }

      it 'gives an error' do
        expect(error_message)
          .to eq I18n.t('bets.notifications.placement_error')
      end
    end
  end

  context 'bonus' do
    let(:bonus_wallet) { wallet }
    let(:bonus_status) { CustomerBonus::ACTIVE }
    let(:sportsbook) { true }
    let!(:customer_bonus) do
      create(:customer_bonus, customer: auth_customer,
                              wallet: bonus_wallet,
                              status: bonus_status,
                              sportsbook: sportsbook)
    end

    let(:odds) { create_list(:odd, 2, :active) }
    let(:variables) do
      {
        bet: {
          amount: 10,
          currencyCode: currency.code,
          odds: odds.map { |odd| { id: odd.id.to_s, value: odd.value } }
        }
      }
    end

    let(:created_bet) { BetLeg.find_by(odd: odds.sample)&.bet }

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
