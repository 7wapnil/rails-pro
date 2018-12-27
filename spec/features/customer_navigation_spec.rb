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

  it 'navigates to customers#activity' do
    within 'ul.navigation' do
      click_link I18n.t('navigation.customer.activity')
      expect(page).to have_current_path(activity_customer_path(customer))
    end
  end

  it 'navigates to customers#notes' do
    within 'ul.navigation' do
      click_link I18n.t('navigation.customer.notes')
      expect(page).to have_current_path(notes_customer_path(customer))
    end
  end

  it 'navigates to customers#bets' do
    within 'ul.navigation' do
      click_link I18n.t('navigation.customer.bets')
      expect(page).to have_current_path(bets_customer_path(customer))
    end
  end
end
