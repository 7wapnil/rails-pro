describe 'Customer Sign In', type: :feature do
  let(:customer) { create(:customer) }

  it 'Sees sign in link in Navbar' do
    visit root_path

    within 'nav.navbar' do
      expect(page).to have_content I18n.t(:sign_in)
      expect(page).to have_content I18n.t(:sign_up)
    end
  end

  context 'Sign In form' do
    before { visit new_customer_session_path }

    it 'Successfully signs in' do
      within 'form#new_customer' do
        fill_in 'customer_username', with: customer.username
        fill_in 'customer_password', with: customer.password

        find('input[name="commit"]').click
      end

      expect(current_path).to eq root_path
      expect(page).to have_content I18n.t('devise.sessions.signed_in')
    end

    it 'Fails to sign in if username or password is invalid' do
      within 'form#new_customer' do
        fill_in 'customer_username', with: customer.username
        fill_in 'customer_password', with: 'iamwrong'

        find('input[name="commit"]').click
      end

      expect_authentication_failure
    end

    it 'Fails to sign in if username is blank' do
      within 'form#new_customer' do
        fill_in 'customer_password', with: customer.password

        find('input[name="commit"]').click
      end

      expect_authentication_failure
    end

    it 'Fails to sign in if password is blank' do
      within 'form#new_customer' do
        fill_in 'customer_username', with: customer.username

        find('input[name="commit"]').click
      end

      expect_authentication_failure
    end
  end

  context 'Signed in' do
    it 'Sees own username in navbar right corner' do
      login_as customer, scope: :customer

      visit root_path

      within 'nav.navbar' do
        expect(page).to have_content customer.username
      end
    end
  end
end

def expect_authentication_failure
  expect(current_path).to eq new_customer_session_path
  expect(page).to have_content I18n.t(
    'devise.failure.invalid',
    authentication_keys: 'Username'
  )
end
