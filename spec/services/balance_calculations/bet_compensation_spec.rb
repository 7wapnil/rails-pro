# frozen_string_literal: true

describe BalanceCalculations::BetCompensation do
  subject(:service_call_response) do
    described_class.call(entry_request: win_entry_request)
  end

  let(:winning) { rand(100..500).to_f }
  let(:bet) { create(:bet, amount: winning) }
  let(:win_entry_request) do
    create(:entry_request, :win, amount: winning, origin: bet)
  end

  let(:amount) { rand(10..100).to_f }
  let(:ratio) { 0.75 }
  let(:placement_entry) { create(:entry, :bet, amount: amount, origin: bet) }
  let!(:real_money_balance_entry) do
    create(:balance_entry, amount: amount * ratio,
                           entry: placement_entry,
                           balance: create(:balance, :real_money))
  end
  let!(:bonus_balance_entry) do
    create(:balance_entry, amount: amount * (1 - ratio),
                           entry: placement_entry,
                           balance: create(:balance, :bonus))
  end

  let(:real_money_winning) { (winning * ratio).round(2) }
  let(:bonus_winning) { (winning * (1 - ratio)).round(2) }

  context 'with placed real money and bonuses' do
    it 'calculates real and bonus amount' do
      expect(service_call_response)
        .to eq(real_money: real_money_winning, bonus: bonus_winning)
    end
  end

  context 'without placed bonuses' do
    let(:bonus_balance_entry) {}

    it 'calculates real amount' do
      expect(service_call_response).to eq(real_money: winning, bonus: 0)
    end
  end

  context 'without placed real money' do
    let(:real_money_balance_entry) {}

    it 'calculates bonus amount' do
      expect(service_call_response).to eq(real_money: 0, bonus: winning)
    end
  end
end
