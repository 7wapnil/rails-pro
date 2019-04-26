# frozen_string_literal: true

describe Bonuses::ExpiringBonusesHandler do
  subject { described_class.call }

  let(:control_count) { rand(3..5) }
  let(:actual_bonuses) { create_list(:customer_bonus, rand(1..3)) }
  let(:expired_bonuses) do
    create_list(:customer_bonus, control_count, :expired)
  end

  let!(:actual_bonus_balances) do
    actual_bonuses.map do |bonus|
      create(:balance, :bonus, wallet_id: bonus.wallet_id)
    end
  end
  let!(:expired_bonus_balances) do
    expired_bonuses.take(control_count - 2).map do |bonus|
      create(:balance, :bonus, wallet_id: bonus.wallet_id)
    end
  end

  let!(:entry_currency_rules) do
    expired_bonuses.map do |bonus|
      create(:entry_currency_rule,
             currency: bonus.wallet.currency,
             min_amount: -1_000,
             max_amount: 0,
             kind: EntryKinds::CONFISCATION)
    end
  end

  let(:control_balance) { expired_bonus_balances.sample }
  let(:control_wallet) { control_balance.wallet }
  let(:control_entry_request) do
    EntryRequest.confiscation.find_by(origin: control_wallet)
  end
  let(:control_entry) { Entry.confiscation.find_by(origin: control_wallet) }

  let(:comment) do
    "Confiscation of #{control_balance.amount} #{control_wallet.currency} " \
    "from #{control_wallet.customer} bonus balance."
  end

  include_context 'asynchronous to synchronous'

  it 'expires expired bonuses' do
    subject
    expect(expired_bonuses.map(&:reload)).to be_all(&:deleted?)
  end

  it 'creates entry requests for expired bonuses with balances' do
    expect { subject }.to change(EntryRequest, :count).by(control_count - 2)
  end

  it 'creates valid confiscation entry request' do
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

  it 'creates valid confiscation entry' do
    subject
    expect(control_entry).to have_attributes(
      amount: -control_balance.amount,
      wallet: control_wallet
    )
  end

  it 'creates only one confiscation balance entry' do
    subject
    expect(control_entry.balance_entries.count).to eq(1)
  end

  it 'create bonus confiscation balance entry' do
    subject
    expect(control_entry.balance_entries.first).to have_attributes(
      balance_id: control_balance.id,
      amount: -control_balance.amount
    )
  end
end
