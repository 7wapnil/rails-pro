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

      within '.container' do
        expect_to_have_notification I18n.t(
          :activated,
          instance: I18n.t('entities.bonus')
        )
      end
    end
  end
end
