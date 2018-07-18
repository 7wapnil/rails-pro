describe 'User Sign In' do
  let(:user) { create(:admin_user) }

  context 'Sign In form' do
    before { visit new_user_session_path }

    it 'Successfully signs in' do
      within 'form#new_user' do
        fill_in 'user_email', with: user.email
        fill_in 'user_password', with: user.password

        click_submit
      end

      expect(current_path).to eq root_path
      expect_to_have_notification I18n.t('devise.sessions.signed_in')
    end

    it 'Fails to sign in if email or password is invalid' do
      within 'form#new_user' do
        fill_in 'user_email', with: user.email
        fill_in 'user_password', with: 'iamwrong'

        click_submit
      end

      expect_authentication_failure
    end

    it 'Fails to sign in if email is blank' do
      within 'form#new_user' do
        fill_in 'user_password', with: user.password

        click_submit
      end

      expect_authentication_failure
    end

    it 'Fails to sign in if password is blank' do
      within 'form#new_user' do
        fill_in 'user_email', with: user.email

        click_submit
      end

      expect_authentication_failure
    end

    context 'Signed in' do
      it 'Sees own full name in navbar right corner' do
        login_as user, scope: :user

        visit root_path

        within 'nav.navbar' do
          expect(page).to have_content user.full_name
        end
      end
    end
  end

  def expect_authentication_failure
    expect(current_path).to eq new_user_session_path
    expect_to_have_notification I18n.t(
      'devise.failure.invalid',
      authentication_keys: 'Email'
    )
  end
end
