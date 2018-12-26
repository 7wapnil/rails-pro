describe 'User Sign In' do
  let(:user) { create(:admin_user) }

  before(:all) { Recaptcha.configuration.skip_verify_env.delete('test') }
  after(:all)  { Recaptcha.configuration.skip_verify_env.push('test') }

  context 'Sign In form' do
    before { visit new_user_session_path }

    it 'Successfully signs in' do
      fill_sign_in_form

      expect(current_path).to eq dashboard_path
      expect_to_have_notification I18n.t('devise.sessions.signed_in')
    end

    it 'Fails to sign in if email or password is invalid' do
      fill_sign_in_form(password: 'iamwrong')

      expect_authentication_failure
    end

    it 'Fails to sign in if email is blank' do
      fill_sign_in_form(email: '')

      expect_authentication_failure
    end

    it 'Fails to sign in if password is blank' do
      fill_sign_in_form(password: '')

      expect_authentication_failure
    end

    context 'suspicious' do
      let(:captcha_message) { I18n.t('recaptcha.errors.verification_failed') }
      let!(:user) do
        create(:admin_user,
               failed_attempts: LoginAttemptable::LOGIN_ATTEMPTS_CAP)
      end

      scenario 'failure login attempt' do
        fill_sign_in_form

        expect_to_have_notification(captcha_message)
        expect { user.reload }.to change { user.failed_attempts }.by(1)
      end

      scenario 'notify about suspicious login' do
        expect_any_instance_of(ArcanebetMailer)
          .to receive(:suspicious_login).with(user.email)

        fill_sign_in_form
      end

      scenario 'successful login attempt' do
        expect_any_instance_of(Users::SessionsController)
          .to receive(:verify_recaptcha).and_return(true)

        fill_sign_in_form

        expect_to_have_notification I18n.t('devise.sessions.signed_in')
        expect(user.reload.failed_attempts).to be_zero
      end
    end

    context 'Signed in' do
      it 'Sees own full name in navbar right corner' do
        login_as user, scope: :user

        visit dashboard_path

        within 'nav.navbar' do
          expect(page).to have_content user.full_name
        end
      end
    end
  end

  def fill_sign_in_form(**args)
    within '#new_user' do
      fill_in 'user_email',    with: args.fetch(:email, user.email)
      fill_in 'user_password', with: args.fetch(:password, user.password)

      click_submit
    end
  end

  def expect_authentication_failure
    expect(current_path).to eq new_user_session_path
    expect(page).not_to have_css('.g-recaptcha')
    expect_to_have_notification I18n.t(
      'devise.failure.invalid',
      authentication_keys: 'Email'
    )
  end
end
