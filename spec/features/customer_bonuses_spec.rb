# frozen_string_literal: true

describe Customer, '#bonuses' do
  let(:customer) { create(:customer) }
  let(:primary_currency) { create(:currency, :primary) }
  let!(:wallet) do
    create(:wallet, customer: customer, currency: primary_currency)
  end
  let!(:bonus) { create(:bonus) }
  let(:page_path) { bonuses_customer_path(customer) }

  before do
    login_as create(:admin_user), scope: :user
    visit page_path
  end

  context 'bonuses' do
    it 'shows bonuses history section' do
      expect_to_have_section 'bonuses'
      expect(page).to have_content(I18n.t('no_records'))
    end
  end

  context 'new bonus activation' do
    it 'shows bonus activation form' do
      expect(page).to have_selector('form.new_customer_bonus')
    end

    it 'selects customer wallet with primary currency' do
      expect(page).to have_field(
        :customer_bonus_wallet_id,
        with: wallet.id
      )
    end

    it 'activates bonus for customer' do
      within 'form.new_customer_bonus' do
        select bonus.code, from: :customer_bonus_original_bonus_id
        fill_in :customer_bonus_amount, with: 100
        select wallet.currency_name, from: :customer_bonus_wallet_id
        click_submit
      end

      within '.container-fluid' do
        expect_to_have_notification I18n.t(
          :activated,
          instance: I18n.t('entities.bonus')
        )
      end
    end
  end

  context 'bonus deactivation' do
    let!(:bonus) do
      create(:customer_bonus, customer: customer,
                              wallet: wallet,
                              status: CustomerBonus::ACTIVE)
    end
    let!(:bonus_balance) { create(:balance, :bonus, wallet: wallet) }

    let(:found_entry_request) do
      EntryRequest.bonus_change.find_by(origin: bonus)
    end

    before do
      allow(EntryRequests::BonusChangeWorker).to receive(:perform_async)
      visit customer_bonus_path(bonus)
      click_link 'Cancel'
    end

    it 'redirects to customer bonuses page' do
      expect(page).to have_current_path(page_path)
    end

    it 'expire customer bonus' do
      expect(page).to have_content('Cancelled')
    end

    it 'status customer bonus changed' do
      bonus.reload

      expect(bonus).to be_expired
    end

    it 'creates bonus change entry request' do
      expect(found_entry_request).to have_attributes(
        mode: EntryRequest::INTERNAL,
        amount: -bonus_balance.amount,
        customer: wallet.customer,
        currency: wallet.currency
      )
    end

    it 'schedules job for updating wallet' do
      expect(EntryRequests::BonusChangeWorker)
        .to have_received(:perform_async)
        .with(found_entry_request.id)
    end
  end
end
