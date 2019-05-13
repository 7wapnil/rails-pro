# frozen_string_literal: true

describe GraphQL, '#wallets' do
  let(:auth_customer) { create(:customer) }
  let(:context) { { current_customer: auth_customer } }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end
  let!(:customer_bonuses) do
    create_list(:customer_bonus, control_count, customer: auth_customer)
  end
  let(:control_count) { rand(2..5) }
  let(:rollover_initial_value) { customer_bonuses.first.rollover_initial_value }

  describe 'query' do
    let(:query) do
      %({ customer_bonuses { id code rollover_balance
                           rollover_initial_value status expires_at} })
    end

    let(:control_date) do
      customer_bonuses.first.expires_at.strftime('%e.%m.%y')
    end

    it 'returns customer bonus info' do
      expect(result['data']['customer_bonuses'].first)
        .to include(
          'id' => customer_bonuses.first.id.to_s,
          'code' => customer_bonuses.first.code,
          'rollover_balance' => customer_bonuses.first.rollover_balance,
          'rollover_initial_value' => rollover_initial_value,
          'status' => customer_bonuses.first.status,
          'expires_at' => control_date
        )
    end

    it 'returns list of customer bonuses' do
      expect(result['data']['customer_bonuses'].count).to eq(control_count)
    end
  end
end
