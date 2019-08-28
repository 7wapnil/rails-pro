# frozen_string_literal: true

describe Audit::Service do
  subject { described_class.call(params) }

  let(:params) { { user: user, event: event } }
  let(:user) { create(:user) }
  let(:event) { :customer_created }

  before do
    allow(AuditLog).to receive(:create)
  end

  context 'log entry' do
    it 'creates a log entry' do
      allow(AuditLog).to receive(:create!)

      subject

      expect(AuditLog)
        .to have_received(:create!)
        .with(event: event,
              user_id: user.id,
              customer_id: nil,
              context: {})
    end

    it 'rescues error' do
      allow(AuditLog)
        .to receive(:create!).and_raise(Mongo::Error::SocketTimeoutError)

      expect { subject }.not_to raise_error
    end

    it 'writes logs' do
      allow(AuditLog)
        .to receive(:create!).and_raise(Mongo::Error::SocketTimeoutError)

      expect_any_instance_of(described_class)
        .to receive(:log_job_message).once

      subject
    end
  end
end
