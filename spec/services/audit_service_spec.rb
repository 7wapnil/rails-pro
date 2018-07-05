describe AuditService do
  let(:user) { create(:user) }

  before do
    allow(AuditLog).to receive(:create)
  end

  context 'log entry' do
    it 'creates a log entry' do
      target = 'Customer'
      action = 'create'
      payload = { id: 1, changes: { name: %i[From To] } }

      AuditService.call target: target,
                        action: action,
                        origin_kind: :user,
                        origin_id: user.id,
                        payload: payload

      expect(AuditLog)
        .to have_received(:create)
        .with(target: target,
              action: action,
              origin: { kind: :user, id: user.id },
              payload: payload)
    end
  end
end
