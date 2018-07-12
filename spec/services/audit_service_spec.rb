describe Audit::Service do
  let(:user) { create(:user) }

  before do
    allow(AuditLog).to receive(:create)
  end

  context 'log entry' do
    it 'creates a log entry' do
      allow(AuditLog).to receive(:create!)

      event = :customer_created
      Audit::Service.call event: event,
                          origin_kind: :user,
                          origin_id: user.id

      expect(AuditLog)
        .to have_received(:create!)
        .with(event: event,
              origin_kind: :user,
              origin_id: user.id,
              context: {})
    end
  end
end
