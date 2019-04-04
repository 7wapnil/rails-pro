describe WithdrawalRequestsController, type: :controller do
  describe '#index' do
    let(:current_user) { create(:admin_user) }
    let(:withdrawal_request) { create(:withdrawal_request) }

    before do
      sign_in current_user
      allow(AuditLog).to receive(:create!)
    end

    context 'when confirming withdrawal request' do
      before do
        post :confirm, params: { id: withdrawal_request.id }
      end

      it 'sets actioned_by' do
        expect(withdrawal_request.reload.actioned_by).to eq current_user
      end
    end
  end
end
