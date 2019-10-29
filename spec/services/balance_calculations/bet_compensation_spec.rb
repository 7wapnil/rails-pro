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
  let!(:bonus_balance) { amount - real_money_balance }

  let(:real_money_winning) { (winning * ratio).round(2) }
  let(:bonus_winning) { (winning - real_money_winning).round(2) }

  context 'with inregular number and round' do
    let(:real_money_balance) { 5.0 }
    let(:bonus_balance)      { 3.0 }
    let(:total_balance)      { bonus_balance + real_money_balance }
    let(:ratio)              { bonus_balance / total_balance }
    let(:winning)            { 9.0 }

    it 'round works correct' do
      entry = Entry.new(
        bonus_amount: subject[:bonus_amount],
        real_money_amount: subject[:real_money_amount]
      )
      entry_winning = entry.bonus_amount + entry.real_money_amount
      expect(entry_winning).to eq(winning)
    end
  end

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
