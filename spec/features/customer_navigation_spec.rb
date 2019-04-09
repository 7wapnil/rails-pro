context 'Customers#show navigation' do
  let(:customer) { create(:customer) }

  before do
    login_as create(:admin_user), scope: :user
    visit customer_path(customer)
  end

  it 'shows navigation links' do
    expect(page).to have_selector('ul.navigation')
  end

  it 'navigates to customers#show' do
    within 'ul.navigation' do
      click_link I18n.t('navigation.customer.account')
      expect(page).to have_current_path(customer_path(customer))
    end
  end

  it 'navigates to customers#account_management' do
    within 'ul.navigation' do
      click_link I18n.t('navigation.customer.account_management')
      expect(page)
        .to have_current_path(account_management_customer_path(customer))
    end
  end

  it 'navigates to customers#activity' do
    within 'ul.navigation' do
      click_link I18n.t('navigation.customer.activity')
      expect(page).to have_current_path(activity_customer_path(customer))
    end
  end

  it 'navigates to customers#bonuses' do
    within 'ul.navigation' do
      click_link I18n.t('navigation.customer.bonuses')
      expect(page).to have_current_path(bonuses_customer_path(customer))
    end
  end

  it 'navigates to customers#notes' do
    within 'ul.navigation' do
      click_link I18n.t('navigation.customer.notes')
      expect(page).to have_current_path(notes_customer_path(customer))
    end
  end

  it 'navigates to customers#documents' do
    within 'ul.navigation' do
      click_link I18n.t('navigation.customer.documents')
      expect(page).to have_current_path(documents_customer_path(customer))
    end
  end

  it 'navigates to customers#bets' do
    within 'ul.navigation' do
      click_link I18n.t('navigation.customer.bets')
      expect(page).to have_current_path(bets_customer_path(customer))
    end
  end

  it 'navigates to customers#betting_limits' do
    within 'ul.navigation' do
      click_link I18n.t('navigation.customer.betting_limits')
      expect(page).to have_current_path(betting_limits_customer_path(customer))
    end
  end

  # FIXME: works IRL, doesn't have @customer in specs
  xit 'navigates to customers#deposit_limit' do
    within 'ul.navigation' do
      click_link I18n.t('navigation.customer.deposit_limit')
      expect(page).to have_current_path(deposit_limit_customer_path(customer))
    end
  end

  it 'navigates to customers#transactions' do
    within 'ul.navigation' do
      click_link I18n.t('entities.transactions')
      expect(page).to have_current_path(transactions_customer_path(customer))
    end
  end
end
