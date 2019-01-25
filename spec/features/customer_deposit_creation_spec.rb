describe 'creates deposit via entry request form' do
  let(:customer) { create(:customer) }
  let(:page_path) { account_management_customer_path(customer) }
  let(:amount) { 200 }
  let(:entries_count) { BalanceEntryRequest.count }
  let(:entries_amounts) { BalanceEntryRequest.pluck(:amount) }
  let!(:currency) { create(:currency, :primary, code: 'EUR', name: 'Euro') }
  let(:rule) { create(:entry_currency_rule, min_amount: 0, max_amount: 500) }
  let(:deposit_form) { '.card.customer-entry-request-form form' }
  let(:comment_text) { 'Comment text' }

  before do
    create(:wallet, customer: customer, currency: currency, amount: 0)
    login_as create(:admin_user), scope: :user
    allow(EntryCurrencyRule).to receive(:find_by!) { rule }
    allow(Currency).to receive(:find_by!) { currency }
    visit page_path
  end

  context 'trigger deposit creation flow' do
    it 'calls Deposits::PlacementService' do
      within deposit_form do
        fill_in 'Amount', with: amount
        fill_in 'Comment', with: comment_text
        select EntryRequest::SIMULATED.capitalize, from: 'Mode'
        select 'Euro', from: 'Currency'

        expect(Deposits::PlacementService).to receive(:call)

        click_on 'Confirm'
      end
    end
  end

  context 'trigger entry placement flow' do
    it "don't call Deposits::PlacementService" do
      within deposit_form do
        fill_in 'Amount', with: amount
        fill_in 'Comment', with: comment_text
        select EntryRequest::CASHIER.capitalize, from: 'Mode'
        select 'Euro', from: 'Currency'

        expect(Deposits::PlacementService).not_to receive(:call)

        click_on 'Confirm'
      end
    end

    it 'passes entry request to EntryRequestProcessingWorker' do
      within deposit_form do
        fill_in 'Amount', with: amount
        fill_in 'Comment', with: comment_text
        select EntryRequest::CASHIER.capitalize, from: 'Mode'
        select 'Euro', from: 'Currency'

        expect(EntryRequestProcessingWorker).to receive(:perform_async)

        click_on 'Confirm'
      end
    end
  end

  context 'with bonus' do
    let(:percentage) { 25 }
    let!(:customer_bonus) do
      create(:customer_bonus,
             customer: customer,
             percentage: percentage,
             rollover_balance: 20)
    end

    it 'creates 2 entries requests' do
      within deposit_form do
        fill_in 'Amount', with: amount
        fill_in 'Comment', with: comment_text
        select 'Simulated', from: 'Mode'
        select 'Euro', from: 'Currency'
        click_on 'Confirm'
        bonus_amount = (percentage / 100.0) * amount

        expect(entries_amounts).to match_array([amount, bonus_amount])
      end
    end

    it 'closes customer bonus when customer bonus is expired' do
      customer_bonus.update_attributes(created_at: 1.month.ago,
                                       valid_for_days: 2)
      within deposit_form do
        fill_in 'Amount', with: amount
        select 'Euro', from: 'Currency'
        fill_in 'Comment', with: comment_text
        select 'Simulated', from: 'Mode'
        click_on 'Confirm'
        customer_bonus.reload

        expect(customer_bonus).to be_expired_by_date
      end
    end
  end

  context 'without bonus' do
    it 'creates 1 entry requests' do
      within deposit_form do
        fill_in 'Amount', with: amount
        select 'Euro', from: 'Currency'
        fill_in 'Comment', with: comment_text
        select 'Simulated', from: 'Mode'
        click_on 'Confirm'

        expect(entries_amounts).to match_array([amount])
      end
    end
  end
end
