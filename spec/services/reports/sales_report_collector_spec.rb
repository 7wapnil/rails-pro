# frozen_string_literal: true

describe Reports::SalesReportCollector do
  subject do
    described_class.new(subject: customer)
  end

  let(:customer) { create(:customer, :ready_to_bet, b_tag: '123123') }
  let(:wallet) { customer.wallet }

  describe 'call' do
    context 'customer has deposit' do
      let(:count) { rand(1..3) }
      let(:bonus_amount) do
        deposits_with_bonus.sum do |b|
          b.balance_entries.bonus.sum(:base_currency_amount)
        end
      end
      let(:gross_revenue) do
        bets.sum(&:base_currency_amount).abs -
          win_bets.sum(&:base_currency_amount).abs
      end

      let(:deposit_real_money_value) do
        deposits.sum do |b|
          b.balance_entries.real_money.sum(:base_currency_amount)
        end
      end

      let!(:deposits) do
        create_list(:entry, count, :recent, :deposit,
                    wallet: wallet,
                    balance_entries: create_list(:balance_entry, 2))
      end

      let!(:deposits_with_bonus) do
        create_list(:entry, count, :recent, :deposit, :with_bonus_balances,
                    wallet: wallet)
      end

      let!(:test_deposits) do
        create_list(:entry, rand(1..3), :deposit,
                    wallet: wallet,
                    balance_entries: create_list(:balance_entry, 2))
      end

      let!(:deposits_with_negative_amount) do
        create_list(:entry, count, :recent, :deposit, :with_bonus_balances,
                    wallet: wallet,
                    base_currency_amount: -rand(1..5),
                    amount: -rand(1..5))
      end

      let!(:bets) do
        create_list(:entry, count, :recent, :bet,
                    wallet: wallet,
                    balance_entries: create_list(:balance_entry, 2),
                    origin: create(:bet, customer: customer, status: :settled))
      end

      let!(:win_bets) do
        create_list(:entry, count, :recent, :win,
                    wallet: wallet,
                    balance_entries: create_list(:balance_entry, 2),
                    origin: create(:bet, customer: customer, status: :settled))
      end

      let!(:test_bets_with_rejected_status) do
        create_list(:entry, rand(1..3), :bet, :recent,
                    wallet: wallet,
                    balance_entries: create_list(:balance_entry, 2),
                    origin: create(:bet, customer: customer, status: :rejected))
      end

      let!(:test_bets) do
        create_list(:entry, rand(1..3), :bet,
                    wallet: wallet,
                    balance_entries: create_list(:balance_entry, 2))
      end

      it 'returns correct number of deposits' do
        result = subject.send(:deposits_count)

        expect(result).to eq(deposits.length + deposits_with_bonus.length)
      end

      it 'returns correct deposit real money value' do
        result = subject.send(:deposit_real_money_converted)

        expect(result).to eq(deposit_real_money_value)
      end

      it 'returns correct deposit bonus value' do
        result = subject.send(:deposit_bonus_converted)

        expect(result).to eq(bonus_amount)
      end

      it 'returns correct gross revenue value' do
        result = subject.send(:gross_revenue)

        expect(result).to eq(gross_revenue)
      end

      it 'returns correct stake amount value' do
        result = subject.send(:stake_amount)

        expect(result).to eq(bets.sum(&:base_currency_amount).abs)
      end
    end
  end
end
