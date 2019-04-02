# frozen_string_literal: true

describe WithdrawalRequest, type: :model do
  subject { build(:withdrawal_request) }

  let(:user) { create(:admin_user) }
  let(:error_message) do
    I18n.t('errors.messages.withdrawal_requests.not_actionable')
  end

  it { is_expected.to belong_to(:actioned_by) }
  it { is_expected.to have_many(:entry_requests) }
  it { is_expected.to have_one(:entry_request) }

  context '#confirm!' do
    subject { withdrawal_request.confirm!(user) }

    context 'on pending request' do
      let(:withdrawal_request) { create(:withdrawal_request) }

      before { subject }

      it 'sets the actioned_by reference' do
        expect(withdrawal_request.actioned_by).to eq user
      end

      it 'sets the status to approved' do
        expect(withdrawal_request.status).to eq WithdrawalRequest::APPROVED
      end
    end

    context 'on rejected request' do
      let(:withdrawal_request) { create(:withdrawal_request, :rejected) }

      it 'throws an exception' do
        expect { subject }.to raise_error(error_message)
      end
    end

    context 'on confirmed requests' do
      let(:withdrawal_request) { create(:withdrawal_request, :approved) }

      it 'throws an exception' do
        expect { subject }.to raise_error(error_message)
      end
    end
  end

  context '#reject!' do
    subject { withdrawal_request.reject!(user, Faker::Lorem.sentence) }

    context 'on pending request' do
      let(:withdrawal_request) { create(:withdrawal_request) }

      before { subject }

      it 'sets the actioned_by reference' do
        expect(withdrawal_request.actioned_by).to eq user
      end

      it 'sets the status to approved' do
        expect(withdrawal_request.status).to eq WithdrawalRequest::REJECTED
      end
    end

    context 'on rejected request' do
      let(:withdrawal_request) { create(:withdrawal_request, :rejected) }

      it 'throws an exception' do
        expect { subject }.to raise_error(error_message)
      end
    end

    context 'on confirmed requests' do
      let(:withdrawal_request) { create(:withdrawal_request, :approved) }

      it 'throws an exception' do
        expect { subject }.to raise_error(error_message)
      end
    end
  end
end
