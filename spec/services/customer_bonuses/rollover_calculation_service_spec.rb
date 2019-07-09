# frozen_string_literal: true

describe CustomerBonuses::RolloverCalculationService do
  let(:bonus) do
    create(
      :customer_bonus,
      min_odds_per_bet: 1.5,
      max_rollover_per_bet: 50,
      rollover_initial_value: 1000,
      rollover_balance: 1000
    )
  end

  let(:odd) { create(:odd, value: 1.85) }

  let(:bet_attributes) do
    {
      status: :settled,
      customer_bonus: bonus,
      odd: odd,
      odd_value: 1.85,
      amount: 10
    }
  end

  # rubocop:disable RSpec/MultipleExpectations
  context 'rollover not updated' do
    it 'when bet is not settled' do
      bet = create(:bet, **bet_attributes.merge(status: :accepted))

      expect { described_class.call(bet) }
        .not_to change(bonus, :rollover_balance)

      expect { described_class.call(bet) }
        .not_to change(bet, :counted_towards_rollover)
    end

    it 'when bet is without a bonus' do
      bet = create(:bet, **bet_attributes.merge(customer_bonus: nil))

      expect { described_class.call(bet) }
        .not_to change(bonus, :rollover_balance)

      expect { described_class.call(bet) }
        .not_to change(bet, :counted_towards_rollover)
    end

    it 'when bonus is not active' do
      customer_bonus = create(
        :customer_bonus,
        status: CustomerBonus::EXPIRED,
        min_odds_per_bet: 1.5
      )
      bet = create(:bet, **bet_attributes.merge(customer_bonus: customer_bonus))

      expect { described_class.call(bet) }
        .not_to change(bonus, :rollover_balance)

      expect { described_class.call(bet) }
        .not_to change(bet, :counted_towards_rollover)
    end

    it 'when odds are lower than min_odds_per_bet' do
      odd = create(:odd, value: 1.49)
      bet = create(:bet, **bet_attributes.merge(odd: odd, odd_value: 1.49))

      expect { described_class.call(bet) }
        .not_to change(bonus, :rollover_balance)

      expect { described_class.call(bet) }
        .not_to change(bet, :counted_towards_rollover)
    end
  end
  # rubocop:enable RSpec/MultipleExpectations

  context 'rollover updated' do
    it 'tags the bet to count towards rollover' do
      bet = create(:bet, **bet_attributes)

      expect { described_class.call(bet) }
        .to change { bet.counted_towards_rollover }
        .from(false)
        .to(true)
    end

    it 'reduces rollover balance by the stake amount' do
      bet = create(:bet, **bet_attributes)

      expect { described_class.call(bet) }
        .to change(bonus, :rollover_balance)
        .from(1000)
        .to(990)
    end

    it 'respects max_rollover_per_bet setting' do
      bet = create(:bet, **bet_attributes.merge(amount: 100))

      expect { described_class.call(bet) }
        .to change(bonus, :rollover_balance)
        .from(1000)
        .to(950)
    end
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'simulates settlement activity' do
    scenario = [
      { stake: 10, odds: 1.50, counts: true, rollover: 990.0 },
      { stake: 50, odds: 1.65, counts: true, rollover: 940.0 },
      { stake: 10, odds: 1.49, counts: false, rollover: 940.0 },
      { stake: 100, odds: 1.12, counts: false, rollover: 940.0 },
      { stake: 49, odds: 2.89, counts: true, rollover: 891.0 },
      { stake: 51, odds: 1.51, counts: true, rollover: 841.0 },
      { stake: 10, odds: 1.10, counts: false, rollover: 841.0 },
      { stake: 100, odds: 3.15, counts: true, rollover: 791.0 },
      { stake: 10, odds: 1.48, counts: false, rollover: 791.0 },
      { stake: 10, odds: 1.35, counts: false, rollover: 791.0 }
    ]

    scenario.each do |payload|
      odd = create(:odd, value: payload[:odds])
      bet = create(
        :bet,
        amount: payload[:stake],
        status: :settled,
        customer_bonus: bonus,
        odd: odd,
        odd_value: payload[:odds]
      )

      described_class.call(bet)

      expect(bet.counted_towards_rollover).to eq(payload[:counts])
      expect(bonus.rollover_balance).to eq(payload[:rollover])
    end
  end
  # rubocop:enable RSpec/MultipleExpectations
end
