describe 'GraphQL#SignIn' do
  let(:request) do
    OpenStruct.new(remote_ip: Faker::Internet.ip_v4_address)
  end
  let(:context) { { request: request } }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  let(:query) do
    %(mutation($input: AuthInput!) {
          signIn(input: $input) {
            user { id }
            token
          }
        })
  end

  before(:all) { Recaptcha.configuration.skip_verify_env.delete('test') }
  after(:all)  { Recaptcha.configuration.skip_verify_env.push('test') }

  context 'wrong input' do
    let(:variables) do
      { input: {} }
    end

    it 'returns argument error' do
      expect(result['errors'][0]['message'])
        .to eq('Variable input of type AuthInput! was provided invalid value')
    end
  end

  context 'non-existing user' do
    let(:variables) do
      { input: {
        login: 'unknown',
        password: '12345'
      } }
    end

    it 'returns wrong credentials error' do
      expect(result['errors'][0]['message'])
        .to eq('Wrong username, email or password')
    end
  end

  context 'non-existing user with captcha argument' do
    let(:variables) do
      { input: {
        login: 'unknown',
        password: '12345',
        captcha: ''
      } }
    end

    it 'returns captcha error' do
      expect(result['errors'][0]['message'])
        .to eq(I18n.t('recaptcha.errors.verification_failed'))
    end
  end

  context 'existing user wrong password' do
    let(:attempts) { 0 }
    let!(:user) do
      create(:customer,
             username: 'testuser',
             password: 'strongpass',
             failed_attempts: attempts)
    end
    let(:variables) do
      { input: {
        login: 'testuser',
        password: '12345'
      } }
    end

    it 'returns wrong credentials' do
      expect(result['errors'][0]['message'])
        .to eq('Wrong username, email or password')
    end

    context 'increment login attempts' do
      it { expect { result }.to change { user.reload.failed_attempts }.by(1) }
    end

    context 'notify about suspicious login' do
      let(:attempts) { LoginAttemptable::LOGIN_ATTEMPTS_CAP }

      before do
        expect_any_instance_of(ArcanebetMailer)
          .to receive(:suspicious_login).with(user.email)
      end

      it 'returns captcha error' do
        expect(result['errors'][0]['message'])
          .to eq(I18n.t('recaptcha.errors.verification_failed'))
      end
    end
  end

  context 'existing user' do
    let(:attempts) { LoginAttemptable::LOGIN_ATTEMPTS_CAP - 1 }
    let!(:user) do
      create(:customer,
             username: 'testuser',
             password: 'strongpass',
             failed_attempts: attempts)
    end
    let(:variables) do
      { input: {
        login: 'testuser',
        password: 'strongpass'
      } }
    end

    context 'request captcha after fixed amount of login attempts' do
      let(:attempts) { LoginAttemptable::LOGIN_ATTEMPTS_CAP }

      it 'returns captcha error' do
        expect(result['errors'][0]['message'])
          .to eq(I18n.t('recaptcha.errors.verification_failed'))
      end

      context 'proceed with verified captcha' do
        before do
          expect_any_instance_of(Account::SignInService)
            .to receive(:verify_recaptcha).and_return(true)
        end

        it { expect(result['data']['signIn']['user']).not_to be_nil }
      end
    end

    it 'signs in successfully' do
      expect(result['data']['signIn']['token']).not_to be_nil
      expect(result['data']['signIn']['user']).not_to be_nil
    end

    it 'logs audit event' do
      allow(Audit::Service).to receive(:call)
      expect(result['data']['signIn']['token']).not_to be_nil
      expect(Audit::Service).to have_received(:call)
    end

    context 'reset login attempts' do
      before { result }

      it { expect(user.reload.failed_attempts).to be_zero }
    end
  end

  context 'existing user with case-insensitive username' do
    let!(:user) do
      create(:customer, username: 'testuser', password: 'strongpass')
    end
    let(:variables) do
      { input: {
        login: 'TESTuSeR',
        password: 'strongpass'
      } }
    end

    it 'signs in successfully' do
      expect(result['data']['signIn']['token']).not_to be_nil
      expect(result['data']['signIn']['user']).not_to be_nil
    end
  end
end
