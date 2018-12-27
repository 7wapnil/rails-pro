describe CustomersController, '#create_fake_deposit' do
  let(:customer) { create(:customer) }
  let(:page_path) { account_management_customer_path(customer) }
  let(:amount) { 200 }
  let(:entries_count) { EntryRequest.count }
  let(:entries_amounts) { EntryRequest.all.map(&:amount) }
  let!(:currency) { create(:currency, code: 'EUR', name: 'Euro') }
  let(:rule) { create(:entry_currency_rule, min_amount: 0, max_amount: 500) }
  let(:deposit_form) { '.customer-deposit-form form' }

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
      create(:customer_bonus, customer: customer, percentage: percentage)
    end

    it 'creates 2 entries requests' do
      within deposit_form do
        fill_in 'Amount', with: amount
        select 'Euro', from: 'Currency'
        click_on 'Confirm'
        bonus_amount = (percentage / 100.0) * amount

        expect(entries_amounts).to match_array([amount, bonus_amount])
      end
    end

    it 'raise error when customer bonus is expired' do
      customer_bonus.update_attributes(created_at: 1.month.ago,
                                       valid_for_days: 2)
      within deposit_form do
        fill_in 'Amount', with: amount
        select 'Euro', from: 'Currency'
        expect { click_on 'Confirm' }.to raise_error StandardError
      end
    end
  end

  context 'without bonus' do
    it 'creates 1 entry requests' do
      within deposit_form do
        fill_in 'Amount', with: amount
        select 'Euro', from: 'Currency'
        click_on 'Confirm'

        expect(entries_amounts).to match_array([amount])
      end
    end
  end
end
