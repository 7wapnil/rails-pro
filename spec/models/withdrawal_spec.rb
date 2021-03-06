# frozen_string_literal: true

describe Withdrawal, type: :model do
  subject { build(:withdrawal) }

  let(:user) { create(:admin_user) }
  let(:error_message) do
    I18n.t('internal.errors.messages.withdrawals.not_actionable')
  end

  it { is_expected.to belong_to(:actioned_by) }
  it { is_expected.to have_many(:entry_requests) }
  it { is_expected.to have_one(:entry_request) }

  context '#confirm!' do
    subject { withdrawal.confirm!(user) }

    before do
      allow(Withdrawals::ProcessPayout).to receive(:call).and_return(true)
    end

    context 'on pending request' do
      let(:withdrawal) { create(:withdrawal) }

      before { subject }

      it 'sets the actioned_by reference' do
        expect(withdrawal.actioned_by).to eq user
      end

      it 'sets the status to processing' do
        expect(withdrawal.status).to eq Withdrawal::PROCESSING
      end
    end

    context 'on rejected request' do
      let(:withdrawal) { create(:withdrawal, :rejected) }

      it 'throws an exception' do
        expect { subject }.to raise_error(error_message)
      end
    end

    context 'on confirmed requests' do
      let(:withdrawal) { create(:withdrawal, :processing) }

      it 'throws an exception' do
        expect { subject }.to raise_error(error_message)
      end
    end
  end

  context '#reject!' do
    subject { withdrawal.reject!(user, Faker::Lorem.sentence) }

    context 'on pending request' do
      let(:withdrawal) { create(:withdrawal) }

      before { subject }

      it 'sets the actioned_by reference' do
        expect(withdrawal.actioned_by).to eq user
      end

      it 'sets the status to rejected' do
        expect(withdrawal.status).to eq Withdrawal::REJECTED
      end
    end

    context 'on rejected request' do
      let(:withdrawal) { create(:withdrawal, :rejected) }

      it 'throws an exception' do
        expect { subject }.to raise_error(error_message)
      end
    end

    context 'on confirmed requests' do
      let(:withdrawal) { create(:withdrawal, :processing) }

      it 'throws an exception' do
        expect { subject }.to raise_error(error_message)
      end
    end
  end
end
