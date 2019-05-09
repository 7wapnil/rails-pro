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
  let!(:customer_bonus) { create(:customer_bonus, customer: auth_customer) }

  describe 'query' do
    let(:query) do
      %({ customer_bonus { id code rollover_balance
                           rollover_initial_value status expires_at} })
    end

    let(:control_date) { customer_bonus.expires_at.strftime('%e.%m.%y') }

    it 'returns customer bonus info' do
      expect(result['data']['customer_bonus'])
        .to include(
          'id' => customer_bonus.id.to_s,
          'code' => customer_bonus.code,
          'rollover_balance' => customer_bonus.rollover_balance,
          'rollover_initial_value' => customer_bonus.rollover_initial_value,
          'status' => customer_bonus.status,
          'expires_at' => control_date
        )
    end
  end
end
