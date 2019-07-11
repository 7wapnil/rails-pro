# frozen_string_literal: true

describe CustomerBonuses::ExpiringBonusesHandler do
  subject { described_class.call }

  let(:control_count) { rand(3..5) }
  let(:actual_bonuses) { create_list(:customer_bonus, rand(1..3)) }

  let(:expired_bonuses) do
    create_list(
      :customer_bonus,
      control_count,
      :with_empty_bonus_balance,
      activated_at: 100.days.ago
    )
  end

  let(:expired_bonuses_with_balance) do
    expired_bonuses.take(control_count - 2)
  end

  let!(:actual_bonus_balances) do
    actual_bonuses.map do |bonus|
      create(:balance, :bonus, wallet_id: bonus.wallet_id)
    end
  end

  let!(:expired_bonus_balances) do
    expired_bonuses_with_balance.map do |bonus|
      balance = Balance.find_by(kind: Balance::BONUS, wallet: bonus.wallet)
      balance.update_attributes(amount: 10)
    end
  end

  let!(:entry_currency_rules) do
    expired_bonuses.map do |bonus|
      create(:entry_currency_rule,
             currency: bonus.wallet.currency,
             min_amount: -1_000,
             max_amount: 0,
             kind: EntryKinds::BONUS_CHANGE)
    end
  end

  let(:control_bonus) { expired_bonuses_with_balance.sample }
  let(:control_wallet) { control_bonus.wallet }
  let!(:control_balance) { control_wallet.bonus_balance }

  let(:control_entry_request) do
    EntryRequest.bonus_change.find_by(origin: control_bonus)
  end
  let(:control_entry) do
    Entry.bonus_change.find_by(origin: control_bonus)
  end

  let(:comment) do
    "Bonus transaction: #{-control_balance.amount} " \
    "#{control_wallet.currency} for #{control_wallet.customer}."
  end

  include_context 'asynchronous to synchronous'
  include_context 'base_currency'

  it 'expires expired bonuses' do
    subject
    expect(expired_bonuses.map(&:reload)).to be_all(&:expired?)
  end

  it 'creates entry requests for expired bonuses with balances' do
    expect { subject }.to change(EntryRequest, :count).by(control_count - 2)
  end

  it 'creates valid bonus change entry request' do
    subject
    expect(control_entry_request).to have_attributes(
      mode: EntryRequest::INTERNAL,
      amount: -control_balance.amount,
      comment: comment,
      customer: control_wallet.customer,
      currency: control_wallet.currency
    )
  end

  it 'creates entries for expired bonuses with balances' do
    expect { subject }.to change(Entry, :count).by(control_count - 2)
  end

  it 'creates valid bonus change entry' do
    subject
    expect(control_entry).to have_attributes(
      amount: -control_balance.amount,
      wallet: control_wallet
    )
  end

  it 'creates only one bonus change balance entry' do
    subject
    expect(control_entry.balance_entries.count).to eq(1)
  end

  it 'create bonus change balance entry' do
    subject
    expect(control_entry.balance_entries.first).to have_attributes(
      balance_id: control_balance.id,
      amount: -control_balance.amount
    )
  end
end
