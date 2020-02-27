# frozen_string_literal: true

describe Audit::Service do
  subject { described_class.call(params) }

  let(:params) { { user: user, event: event } }
  let(:user) { create(:user) }
  let(:event) { 'customer_created' }

  before do
    allow(AuditLog).to receive(:create)
    Sidekiq::Testing.inline!
  end

  after { Sidekiq::Testing.fake! }

  context 'log entry' do
    it 'creates a log entry' do
      allow(AuditLog).to receive(:create!)

      subject

      expect(AuditLog)
        .to have_received(:create!)
        .with hash_including('event' => event,
                             'user_id' => user.id,
                             'customer_id' => nil,
                             'context' => {})
    end
  end
end
