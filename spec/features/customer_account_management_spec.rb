describe Customer, '#account_management' do
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
      wallets = create_list(:wallet, 3, customer: customer)
      wallets.each do |wallet|
        create(:balance, :bonus, wallet: wallet)
        create(:balance, :real_money, wallet: wallet)
      end

      visit page_path

      within '.balances' do
        customer.wallets.each do |wallet|
          expect(page).to have_content wallet.currency_name
          wallet.balances.each do |balance|
            expect(page).to have_content(balance.amount)
          end
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

      within '.container-fluid' do
        expect_to_have_notification(I18n.t('messages.entry_request.flash'))
      end
    end

    it 'displays select option for cashier and simulated modes only' do
      within '.card.customer-entry-request-form #entry_request_mode' do
        options = all('option').map(&:text).map(&:downcase)
        supported_options = [EntryRequest::CASHIER,
                             EntryRequest::SIMULATED,
                             EntryRequest::VISA_MASTERCARD].map(&:downcase)

        expect(options).to match_array(supported_options)
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

  context 'entries table' do
    it 'shows Balance interactions section' do
      expect_to_have_section 'customer-entries'
    end

    it 'shows existing entries' do
      wallet = create(:wallet, customer: customer)
      entries = create_list(:entry, 3, wallet: wallet)

      visit page_path

      within '.customer-entries' do
        entries.each do |entry|
          link_to_entry = I18n.l(entry.created_at, format: :long)

          expect(page).to have_link(link_to_entry, href: entry_path(entry))
          expect(page).to have_content I18n.t "kinds.#{entry.kind}"
          expect(page).to have_content entry.amount
          expect(page).to have_content entry.currency_code
        end
      end
    end

    it 'shows no records note' do
      expect(page).to have_content I18n.t(:no_records)
    end
  end
end
