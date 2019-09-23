# frozen_string_literal: true

describe ::Reports::Queries::SalesReportQuery do
  subject { described_class }

  let(:control_customers) do
    create_list(:customer, rand(1..5), b_tag: '123123')
  end
  let!(:test_customers) { create_list(:customer, 3) }
  let(:deposit_real_money_control_value) do
    control_customers.first.entries.deposit.sum do |b|
      b.balance_entries.real_money.sum(:base_currency_amount)
    end
  end
  let(:bonus_amount_control_value) do
    control_customers.first.entries.deposit.sum do |b|
      b.balance_entries.bonus.sum(:base_currency_amount)
    end
  end
  let(:bets_stake_control_value) do
    control_customers.first
                     .entries
                     .bet
                     .confirmed
                     .sum(&:base_currency_amount)
                     .abs
  end
  let(:ggr_control_value) do
    bets_stake_control_value -
      control_customers.first.entries.win.sum(&:base_currency_amount).abs
  end
  let(:ngr) { 0.175 }

  before do
    control_customers.each do |customer|
      wallet = create(:wallet, customer: customer,
                               currency: create(:currency, :primary))
      create(:entry, :bet, :recent,
             wallet: wallet,
             entry_request: nil,
             origin: create(:bet, :recently_settled, customer: customer))
      create(:entry, :bet, :recent, :confirmed,
             wallet: wallet,
             entry_request: nil,
             origin: create(:bet, :recently_settled, customer: customer))
      create(:entry, :deposit, :recent, :with_balance_entries,
             wallet: wallet,
             entry_request: nil)
      create(:entry, :win, :recent,
             wallet: wallet,
             entry_request: nil,
             origin: create(:bet, customer: customer,
                                  status: :settled,
                                  settlement_status: :lost))
    end

    test_customers.each do |customer|
      wallet = create(:wallet, customer: customer,
                               currency: create(:currency, :primary))
      create(:entry, :bet, wallet: wallet, entry_request: nil)
      create(:entry, :bet, :confirmed, wallet: wallet, entry_request: nil)
      create(:entry, :deposit, wallet: wallet, entry_request: nil)
      create(:entry, :win, wallet: wallet, entry_request: nil)
    end
  end

  describe '#batch_loader' do
    def results
      results = []

      subject.new.batch_loader { |records| results += records.to_a }
      results
    end

    it 'returns correct amount of records' do
      expect(results.length).to eq(control_customers.length)
    end

    it 'returns correct deposits count' do
      expect(results.first['deposits_count'])
        .to eq(control_customers.first.entries.deposit.length)
    end

    it 'returns correct deposits real money' do
      expect(results.first['real_money'].to_f)
        .to eq(deposit_real_money_control_value.to_f)
    end

    it 'returns correct deposits bonus money' do
      expect(results.first['bonus_money'].to_f)
        .to eq((bonus_amount_control_value.to_f +
               deposit_real_money_control_value.to_f * ngr).round(2))
    end

    it 'returns correct bets count' do
      expect(results.first['bets_count'].to_i)
        .to eq(control_customers.first.entries.bet.confirmed.count)
    end

    it 'returns correct bets stake' do
      expect(results.first['stake'].to_f.abs)
        .to eq(bets_stake_control_value.to_f)
    end

    it 'returns correct ggr' do
      expect(results.first['ggr'].to_f).to eq(ggr_control_value.to_f)
    end
  end
end
