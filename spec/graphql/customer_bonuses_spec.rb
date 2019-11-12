# frozen_string_literal: true

describe GraphQL, '#customerBonuses' do
  let(:auth_customer) { create(:customer) }
  let(:request) do
    OpenStruct.new(remote_ip: Faker::Internet.ip_v4_address)
  end
  let(:context) { { current_customer: auth_customer, request: request } }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end
  let!(:customer_bonuses) do
    create_list(:customer_bonus, count, customer: auth_customer)
  end
  let!(:cancelled_customer_bonus) do
    create(:customer_bonus, :cancelled, customer: auth_customer)
  end
  let!(:expired_customer_bonus) do
    create(:customer_bonus, :expired, customer: auth_customer)
  end
  let(:count) { rand(2..5) }
  let(:control_count) { count + 2 }
  let(:rollover_initial_value) { customer_bonuses.first.rollover_initial_value }
  let(:rollover_expired_initial_value) do
    expired_customer_bonus.rollover_initial_value
  end
  let(:rollover_cancelled_initial_value) do
    cancelled_customer_bonus.rollover_initial_value
  end

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
          casino
          sportsbook
        }
      })
    end

    let(:control_date) do
      customer_bonuses.first.active_until_date.strftime('%e.%m.%y')
    end

    let(:control_customer_bonus) { customer_bonuses.first.decorate }
    let(:control_expired_customer_bonus) do
      expired_customer_bonus.decorate
    end
    let(:control_cancelled_customer_bonus) do
      cancelled_customer_bonus.decorate
    end

    it 'returns control expired customer bonus info' do
      expect(result['data']['customerBonuses'].last)
        .to include(
          'id' => control_expired_customer_bonus.id.to_s,
          'code' => control_expired_customer_bonus.code,
          'rolloverBalance' =>
            control_expired_customer_bonus.rollover_balance.to_d,
          'rolloverInitialValue' => rollover_expired_initial_value.to_d,
          'status' => CustomerBonus::ACTIVE,
          'expiresAt' =>
            control_expired_customer_bonus.active_until_date(human: true),
          'amount' => control_expired_customer_bonus.amount(human: true)
        )
    end

    it 'returns control cancelled customer bonus info' do
      expect(result['data']['customerBonuses'][-2])
        .to include(
          'id' => control_cancelled_customer_bonus.id.to_s,
          'code' => control_cancelled_customer_bonus.code,
          'rolloverBalance' =>
            control_cancelled_customer_bonus.rollover_balance.to_d,
          'rolloverInitialValue' => rollover_cancelled_initial_value.to_d,
          'status' => CustomerBonus::CANCELLED,
          'expiresAt' =>
            control_cancelled_customer_bonus.active_until_date(human: true),
          'amount' => control_cancelled_customer_bonus.amount(human: true),
          'casino' => false,
          'sportsbook' => true
        )
    end

    it 'returns control customer bonus info' do
      expect(result['data']['customerBonuses'].first)
        .to include(
          'id' => control_customer_bonus.id.to_s,
          'code' => control_customer_bonus.code,
          'rolloverBalance' => control_customer_bonus.rollover_balance.to_d,
          'rolloverInitialValue' => rollover_initial_value.to_d,
          'status' => CustomerBonus::ACTIVE,
          'expiresAt' => control_date,
          'amount' => control_customer_bonus.amount(human: true),
          'casino' => false,
          'sportsbook' => true
        )
    end

    it 'returns list of customer bonuses' do
      expect(result['data']['customerBonuses'].count).to eq(control_count)
    end
  end
end
