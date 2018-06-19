describe 'Customers#activity' do
  let(:customer) { create(:customer) }
  let(:page_path) { activity_backoffice_customer_path(customer) }

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

  context 'entry request' do
    it 'shows entry request form' do
      expect_to_have_section 'customer-entry-request'
    end

    it 'creates new customer entry request' do
      allow(EntryRequestProcessingJob).to receive(:perform_later)

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
        request = EntryRequest.last
        message = ActionController::Base
                  .helpers
                  .strip_tags I18n.t(
                    'entities.entry_request.flash',
                    entry_request_url: backoffice_entry_request_path(request)
                  )
        expect(page).to have_content(message)
      end
    end
  end

  context 'activity' do
    it 'shows activity section' do
      expect_to_have_section 'activity'
    end

    it 'shows available entries' do
      wallet = create(:wallet, customer: customer)
      rule = create(:entry_currency_rule,
                    currency: wallet.currency,
                    min_amount: 10,
                    max_amount: 500)
      create_list(:entry, 10, wallet: wallet, kind: rule.kind, amount: 100)

      visit page_path

      within '.activity' do
        customer.entries.each do |entry|
          expect(page).to have_content entry.kind
          expect(page).to have_content entry.amount
          expect(page).to have_content entry.wallet.currency_code
        end
      end
    end

    it 'shows no records note' do
      expect(page).to have_content I18n.t(:no_records)
    end
  end
end
