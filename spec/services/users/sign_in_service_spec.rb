describe Users::SignInService do
  subject { described_class.new(params) }

  before(:all) { Recaptcha.configuration.skip_verify_env.delete('test') }
  after(:all)  { Recaptcha.configuration.skip_verify_env.push('test') }

  let(:model)    { User }
  let(:email)    { Faker::Internet.email }
  let(:attempts) { rand(2..5) }
  let(:session)  { { last_login: email, attempts: attempts } }
  let(:params) do
    {
      model:   model,
      email:   email,
      session: session
    }
  end

  describe '#login_user' do
    context 'found' do
      let!(:user) { create(:user, email: email) }

      it { expect(subject.login_user).to eq(user) }
    end

    context 'not found' do
      it { expect(subject.login_user).to be_nil }
    end
  end

  describe '#email' do
    it { expect(subject.email).to eq(email) }
  end

  describe '#last_login' do
    it { expect(subject.last_login).to eq(email) }

    context 'with another last login in session' do
      let(:another_email) { Faker::Internet.email }
      let(:session)       { Hash[:last_login, another_email] }

      it { expect(subject.last_login).to eq(another_email) }
    end
  end

  describe '#calculate_attempts' do
    context 'with another last login' do
      let(:another_email) { Faker::Internet.email }
      let(:session)       { Hash[:last_login, another_email] }

      it do
        expect(subject.calculate_attempts)
          .to eq(Users::SignInService::FIRST_ATTEMPT)
      end
    end

    context 'with same last login' do
      it { expect(subject.calculate_attempts).to eq(attempts + 1) }
    end
  end

  describe '#suspected?' do
    let(:attempts)        { Users::SignInService::FIRST_ATTEMPT }
    let(:failed_attempts) { LoginAttemptable::LOGIN_ATTEMPTS_CAP }

    context 'when found user is suspected' do
      let!(:user) do
        create(:user, email: email, failed_attempts: failed_attempts)
      end

      it { expect(subject.suspected?).to be_truthy }
    end

    context 'when user was not found' do
      it { expect(subject.suspected?).to be_falsey }

      context 'with a lot of attempts in session' do
        let(:attempts) { failed_attempts }

        it { expect(subject.suspected?).to be_truthy }
      end
    end
  end
end
