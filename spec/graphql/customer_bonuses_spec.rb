# frozen_string_literal: true

describe GraphQL, '#customerBonuses' do
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
      %({
        customerBonuses {
          id
          code
          rolloverBalance
          rolloverInitialValue
          status
          expiresAt
          amount
        }
      })
    end

    let(:control_date) do
      customer_bonuses.first.expires_at.strftime('%e.%m.%y')
    end

    let(:control_customer_bonus) { customer_bonuses.first.decorate }

    it 'returns customer bonus info' do
      expect(result['data']['customerBonuses'].first)
        .to include(
          'id' => control_customer_bonus.id.to_s,
          'code' => control_customer_bonus.code,
          'rolloverBalance' => control_customer_bonus.rollover_balance.to_d,
          'rolloverInitialValue' => rollover_initial_value.to_d,
          'status' => CustomerBonus::ACTIVE,
          'expiresAt' => control_date,
          'amount' => control_customer_bonus.amount(human: true)
        )
    end

    it 'returns list of customer bonuses' do
      expect(result['data']['customerBonuses'].count).to eq(control_count)
    end
  end
end
