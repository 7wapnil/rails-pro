shared_examples 'LoginAttemptable' do
  let(:attempts)    { LoginAttemptable::LOGIN_ATTEMPTS_CAP }
  let(:auth_entity) do
    create(described_class.model_name.i18n_key, failed_attempts: attempts)
  end

  describe '#valid_for_authentication?' do
    it { expect(auth_entity.valid_for_authentication?).to be_truthy }

    context 'with persisted authentication entity' do
      it { expect(auth_entity.valid_for_authentication?).to be_truthy }

      it do
        expect { auth_entity.valid_for_authentication? }
          .to change { auth_entity.reload.failed_attempts }.to(0)
      end

      it do
        expect { auth_entity.valid_for_authentication? { false } }
          .to change { auth_entity.reload.failed_attempts }.by(1)
      end
    end
  end

  describe '#valid_login_attempt!' do
    it { expect(auth_entity.valid_login_attempt!).to be_truthy }
    it do
      expect { auth_entity.valid_login_attempt! }
        .to change { auth_entity.reload.failed_attempts }.to(0)
    end
  end

  describe '#invalid_login_attempt!' do
    it { expect(auth_entity.invalid_login_attempt!).to be_falsey }
    it do
      expect { auth_entity.invalid_login_attempt! }
        .to change { auth_entity.reload.failed_attempts }.by(1)
    end

    context 'notify account owner' do
      before do
        expect_any_instance_of(ArcanebetMailer)
          .to receive(:suspicious_login).with(auth_entity.email)
      end

      it { auth_entity.invalid_login_attempt! }
    end
  end

  describe 'attempts_just_exceeded?' do
    it { expect(auth_entity.attempts_just_exceeded?).to be_falsey }

    context 'positive' do
      let(:attempts) { LoginAttemptable::LOGIN_ATTEMPTS_CAP + 1 }

      it { expect(auth_entity.attempts_just_exceeded?).to be_truthy }
    end
  end

  describe 'suspicious_login?' do
    it { expect(auth_entity.suspicious_login?).to be_truthy }

    context 'negative' do
      let(:attempts) { LoginAttemptable::LOGIN_ATTEMPTS_CAP - 1 }

      it { expect(auth_entity.suspicious_login?).to be_falsey }
    end
  end
end
