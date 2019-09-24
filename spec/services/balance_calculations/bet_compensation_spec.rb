# frozen_string_literal: true

describe BalanceCalculations::BetCompensation do
  subject do
    described_class.call(bet: bet, amount: winning)
  end

  let(:winning) { rand(100..500).to_f }
  let(:bet) { create(:bet, :with_placement_entry, amount: winning) }

  let(:amount) { rand(10..100).to_f }
  let(:ratio) { 0.75 }
  let!(:placement_entry_balance) do
    bet.placement_entry.update(
      real_money_amount: real_money_balance,
      bonus_amount: bonus_balance
    )
  end
  let!(:real_money_balance) { amount * ratio }
  let!(:bonus_balance) { amount * (1 - ratio) }

  let(:real_money_winning) { (winning * ratio).round(2) }
  let(:bonus_winning) { (winning * (1 - ratio)).round(2) }

  context 'with placed real money and bonuses' do
    it 'calculates real and bonus amount' do
      expect(subject)
        .to eq(real_money_amount: real_money_winning,
               bonus_amount: bonus_winning)
    end
  end

  context 'without placed bonuses' do
    let(:bonus_balance) { 0 }

    it 'calculates real amount' do
      expect(subject).to eq(real_money_amount: winning, bonus_amount: 0)
    end
  end

  context 'without placed real money' do
    let(:real_money_balance) { 0 }

    it 'calculates bonus amount' do
      expect(subject).to eq(real_money_amount: 0, bonus_amount: winning)
    end
  end
end
