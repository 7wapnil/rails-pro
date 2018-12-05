describe 'Customers#account_management' do
  let(:customer) { create(:customer) }
  let(:page_path) { account_management_customer_path(customer) }

  before do
    login_as create(:admin_user), scope: :user
    visit page_path
  end

  context 'balances' do
    it 'shows customers balance section' do
      expect_to_have_section 'balances'
    end

    it 'shows available balances' do
      create_list(:wallet, 3, customer: customer)

      visit page_path

      within '.balances' do
        customer.wallets.each do |wallet|
          expect(page).to have_content wallet.currency_name
          expect(page).to have_content wallet.amount
        end
      end
    end

    it 'shows no records note' do
      within '.balances' do
        expect(page).to have_content I18n.t(:no_records)
      end
    end
  end

  context 'entry request form' do
    it 'shows entry request form' do
      expect_to_have_section 'customer-entry-request-form'
    end

    it 'creates new customer entry request' do
      allow(EntryRequestProcessingWorker).to receive(:perform_async)

      currency = create(:currency)
      create(:entry_currency_rule, currency: currency, kind: :deposit)

      visit page_path

      within 'form#new_entry_request' do
        select I18n.t('kinds.deposit'), from: :entry_request_kind
        fill_in :entry_request_amount, with: 200.00
        fill_in :entry_request_comment, with: 'A reason'
        click_submit
      end

      within '.container' do
        expect_to_have_notification(I18n.t('messages.entry_request.flash'))
      end
    end
  end

  context 'entry requests table' do
    it 'shows activity section' do
      expect_to_have_section 'customer-entry-requests'
    end

    it 'shows existing entry requests' do
      create_list(:entry_request, 10,
                  customer: customer,
                  initiator: create(:user))

      visit page_path

      within '.customer-entry-requests' do
        customer.entry_requests.each do |request|
          expect(page).to have_content I18n.t "kinds.#{request.kind}"
          expect(page).to have_content request.mode
          expect(page).to have_content request.amount
          expect(page).to have_content request.currency_code
          expect(page).to have_content I18n.t "statuses.#{request.status}"
        end
      end
    end

    it 'shows no records note' do
      expect(page).to have_content I18n.t(:no_records)
    end
  end
end
