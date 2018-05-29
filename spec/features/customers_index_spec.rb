describe 'Customers#index', type: :feature do

  it 'is protected' do
    visit backoffice_customers_path

    expect(current_path).to eq new_user_session_path
    expect(page).to have_content I18n.t('devise.failure.unauthenticated')
  end

  context 'signed in' do
    let(:per_page_count) { 10 }
    let(:user) { create(:user) }

    before do
      create_list(:customer, 5)

      login_as user, scope: :user
      visit backoffice_customers_path
    end

    it 'shows customers list' do
      within 'table.table' do
        Customer.limit(per_page_count).each do |customer|
          expect(page).to have_content(customer.username)
          expect(page).to have_content(customer.email)
          expect(page).to have_content(customer.last_sign_in_ip)
          expect(page).to have_content(customer.id)
        end
      end
    end

    context 'pagination' do
      it 'is shown' do
        create_list(:customer, 10)
        visit backoffice_customers_path
        expect(page).to have_selector('ul.pagination')
      end

      it 'is hidden' do
        expect(page).not_to have_selector('ul.pagination')
      end
    end

    it 'searches by username contains'

    it 'searches by email contains'

    it 'searches by ip address'

    it 'searches by id'
  end
end
