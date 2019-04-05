describe WithdrawalRequests::Review do
  let(:withdrawal_request) { create(:withdrawal_request) }
  let(:acting_user) { create(:admin_user) }

  context 'confirming withdrawal request' do
    before do
      described_class.call(withdrawal_request: withdrawal_request,
                           user: acting_user,
                           action: :confirm)
    end

    it 'sets the actioned_by reference' do
      expect(withdrawal_request.actioned_by).to be acting_user
    end

    it 'sets the status to approved' do
      expect(withdrawal_request.status).to eq WithdrawalRequest::APPROVED
    end
  end

  context 'rejecting withdrawal request' do
    before do
      described_class.call(withdrawal_request: withdrawal_request,
                           user: acting_user,
                           action: :reject,
                           comment: Faker::Lorem.sentence)
    end

    it 'sets the actioned_by reference' do
      expect(withdrawal_request.actioned_by).to be acting_user
    end

    it 'sets the status to approved' do
      expect(withdrawal_request.status).to eq WithdrawalRequest::REJECTED
    end
  end
end
