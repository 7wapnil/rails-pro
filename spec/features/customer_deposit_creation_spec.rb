describe 'creates deposit via entry request form' do
  let(:customer) { create(:customer) }
  let(:page_path) { account_management_customer_path(customer) }
  let(:amount) { 200 }
  let(:entries_count) { BalanceEntryRequest.count }
  let(:entries_amounts) { BalanceEntryRequest.pluck(:amount) }
  let!(:currency) { create(:currency, :primary, code: 'EUR', name: 'Euro') }
  let(:rule) { create(:entry_currency_rule, min_amount: 0, max_amount: 500) }
  let(:deposit_form) { '.card.customer-entry-request-form form' }
  let(:entry_request_form) { EntryRequestForm.new }

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
        entry_request_form.fill_in_with(mode: EntryRequest::SIMULATED,
                                        type: EntryRequest::DEPOSIT)

        expect(Deposits::PlacementService).to receive(:call)

        entry_request_form.submit
      end
    end
  end

  context 'trigger entry placement flow' do
    let(:filled_form) do
      entry_request_form.fill_in_with(mode: EntryRequest::CASHIER,
                                      type: EntryRequest::DEPOSIT)
    end

    it "don't call Deposits::PlacementService" do
      within deposit_form do
        expect(Deposits::PlacementService).not_to receive(:call)

        filled_form.submit
      end
    end

    it 'passes entry request to EntryRequestProcessingWorker' do
      within deposit_form do
        expect(EntryRequestProcessingWorker).to receive(:perform_async)

        filled_form.submit
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
    let(:filled_form) do
      entry_request_form.fill_in_with(amount: amount,
                                      mode: EntryRequest::SIMULATED,
                                      type: EntryRequest::DEPOSIT)
    end

    it 'creates 2 entries requests' do
      within deposit_form do
        filled_form.submit
        bonus_amount = (percentage / 100.0) * amount

        expect(entries_amounts).to match_array([amount, bonus_amount])
      end
    end

    it 'closes customer bonus when customer bonus is expired' do
      customer_bonus.update_attributes(created_at: 1.month.ago,
                                       valid_for_days: 2)
      within deposit_form do
        filled_form.submit
        customer_bonus.reload

        expect(customer_bonus).to be_expired_by_date
      end
    end
  end

  context 'without bonus' do
    it 'creates 1 entry requests' do
      within deposit_form do
        entry_request_form.fill_in_with(amount: amount,
                                        mode: EntryRequest::SIMULATED,
                                        type: EntryRequest::DEPOSIT).submit

        expect(entries_amounts).to match_array([amount])
      end
    end
  end
end
