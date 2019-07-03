# frozen_string_literal: true

describe 'creates deposit via entry request form' do
  let(:customer) { create(:customer) }
  let(:page_path) { account_management_customer_path(customer) }
  let(:amount) { 200 }
  let(:entries_count) { BalanceEntryRequest.count }
  let(:entries_amounts) { BalanceEntryRequest.pluck(:amount) }
  let!(:currency) { create(:currency, :primary, code: 'EUR', name: 'Euro') }
  let(:rule) { create(:entry_currency_rule, min_amount: 0, max_amount: 500) }
  let(:deposit_form) { '.card.customer-entry-request-form form' }

  before do
    create(:wallet, customer: customer, currency: currency, amount: 0)
    login_as create(:admin_user), scope: :user
    allow(EntryCurrencyRule).to receive(:find_by!) { rule }
    allow(Currency).to receive(:find_by!) { currency }
    visit page_path
  end

  context 'with bonus' do
    let(:percentage) { 25 }
    let!(:customer_bonus) do
      create(:customer_bonus,
             customer: customer,
             percentage: percentage,
             rollover_balance: 20)
    end

    before do
      within deposit_form do
        fill_in 'Amount', with: amount
        fill_in 'Comment', with: 'comment text'
        select EntryRequest::SIMULATED.capitalize, from: 'Mode'
        select EntryRequest::DEPOSIT.capitalize, from: 'Kind'
        select currency.name.capitalize, from: 'Currency'
      end
    end

    it 'creates only RM balance entry requests' do
      click_on 'Confirm'

      expect(entries_amounts).to match_array([amount])
    end
  end

  context 'without bonus' do
    it 'creates 1 entry requests' do
      within deposit_form do
        fill_in 'Amount', with: amount
        fill_in 'Comment', with: 'comment text'
        select EntryRequest::SIMULATED.capitalize, from: 'Mode'
        select EntryRequest::DEPOSIT.capitalize, from: 'Kind'
        select currency.name.capitalize, from: 'Currency'
        click_on 'Confirm'
      end

      expect(entries_amounts).to match_array([amount])
    end
  end
end
