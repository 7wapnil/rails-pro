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
                          user: user

      expect(AuditLog)
        .to have_received(:create!)
        .with(event: event,
              user_id: user.id,
              customer_id: nil,
              context: {})
    end
  end
end
