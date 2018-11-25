describe Account::SignInService do
  subject { described_class.new(customer: customer, params: params) }

  before(:all) { Recaptcha.configuration.skip_verify_env.delete('test') }
  after(:all)  { Recaptcha.configuration.skip_verify_env.push('test') }

  let(:customer) { create(:customer) }
  let(:password) { customer&.password }
  let(:captcha)  { '' }
  let(:params)   { { password: password, captcha: captcha } }

  describe '#captcha_invalid?' do
    it { expect(subject.captcha_invalid?).to be_truthy }

    context 'with suspicious user' do
      let(:captcha) { nil }
      let(:customer) do
        create(:customer,
               failed_attempts: LoginAttemptable::LOGIN_ATTEMPTS_CAP)
      end

      it { expect(subject.captcha_invalid?).to be_truthy }
    end

    context 'negative' do
      context 'with valid captcha' do
        before do
          expect(subject)
            .to receive(:verify_recaptcha)
            .with(response: captcha, skip_remote_ip: true)
            .and_return(true)
        end

        it { expect(subject.captcha_invalid?).to be_falsey }
      end

      context 'without user and captcha' do
        let(:captcha)  { nil }
        let(:customer) { nil }

        it { expect(subject.captcha_invalid?).to be_falsey }
      end

      context 'with normal user without captcha' do
        let(:captcha) { nil }

        it { expect(subject.captcha_invalid?).to be_falsey }
      end
    end
  end

  describe '#invalid_captcha!' do
    let(:error) do
      GraphQL::ExecutionError.new(
        I18n.t('recaptcha.errors.verification_failed')
      )
    end

    it { expect(subject.invalid_captcha!).to eq(error) }

    it do
      expect { subject.invalid_captcha! }
        .to change { customer.reload.failed_attempts }.by(1)
    end
  end

  describe '#invalid_password?' do
    it { expect(subject.invalid_password?).to be_falsey }

    context 'negative' do
      let(:password) { Faker::WorldOfWarcraft.name }

      it { expect(subject.invalid_password?).to be_truthy }
    end
  end

  describe '#invalid_login!' do
    let(:error) do
      GraphQL::ExecutionError.new(
        I18n.t('errors.messages.wrong_login_credentials')
      )
    end

    it { expect(subject.invalid_login!).to eq(error) }

    it do
      expect { subject.invalid_login! }
        .to change { customer.reload.failed_attempts }.by(1)
    end
  end

  describe '#login_response' do
    context 'for common user' do
      let(:jwt_params) do
        {
          id:       customer.id,
          username: customer.username,
          email:    customer.email
        }
      end

      let(:response) { subject.login_response }

      before do
        expect(subject).not_to receive(:account_locked_response)
        expect(customer).to    receive(:log_event).with(:customer_signed_in)

        expect(JwtService)
          .to receive(:encode).with(jwt_params).and_return(:token)
      end

      it do
        expect(response).to       be_a(OpenStruct)
        expect(response.token).to eq(:token)
        expect(response.user).to  eq(customer)
      end
    end

    context 'for locked user' do
      let(:customer) { build(:customer, locked: true) }
      let(:error) do
        GraphQL::ExecutionError.new(
          I18n.t('errors.messages.account_locked.default')
        )
      end

      before do
        expect(subject).not_to receive(:response)
        expect(customer)
          .to receive(:log_event).with(:locked_customer_sign_in_attempt)
      end

      it { expect(subject.login_response).to eq(error) }

      context 'with until time' do
        let(:customer) do
          build(:customer, locked: true, locked_until: 1.day.from_now)
        end

        let(:message) do
          I18n.t(
            'errors.messages.account_locked.default',
            additional_info: I18n.t(
              'errors.messages.account_locked.additional_info.until',
              until_date: customer.locked_until.strftime(
                I18n.t('date.formats.default')
              )
            )
          )
        end

        let(:error) { GraphQL::ExecutionError.new(message) }

        it { expect(subject.login_response).to eq(error) }
      end
    end
  end
end
