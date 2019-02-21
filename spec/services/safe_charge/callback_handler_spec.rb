describe SafeCharge::CallbackHandler do
  let(:invalid_context) { Faker::Lorem.word }

  let(:entry_request) do
    build_stubbed(:entry_request,
                  kind: EntryRequest::DEPOSIT,
                  status: EntryRequest::INITIAL)
  end

  let(:params) { { unique: :hash } }
  let(:approved_reply) do
    instance_double(
      SafeCharge::DepositResponse,
      'validate!' => true,
      'approved?' => true,
      'pending?' => false,
      'entry_request' => entry_request
    )
  end

  let(:pending_reply) do
    instance_double(
      SafeCharge::DepositResponse,
      'validate!' => true,
      'approved?' => false,
      'pending?' => true,
      'entry_request' => entry_request
    )
  end

  let(:cancel_reply) do
    instance_double(
      SafeCharge::DepositResponse,
      'validate!' => true,
      'approved?' => false,
      'pending?' => false,
      'entry_request' => entry_request
    )
  end

  before do
    allow(entry_request).to receive('succeeded!')
    allow(entry_request).to receive('failed!')
  end

  describe '#call' do
    [
      {
        name: 'invalid checksum',
        error: SafeCharge::DepositResponse::AUTHENTICATION_ERROR,
        outcome: Deposits::CallbackUrl::ERROR
      },
      {
        name: 'invalid entry request state',
        error: SafeCharge::DepositResponse::TYPE_ERROR,
        outcome: Deposits::CallbackUrl::FAILED_ENTRY_REQUEST
      },
      {
        name: 'unknown source',
        error: SafeCharge::DepositResponse::AUTHENTICATION_ERROR,
        outcome: Deposits::CallbackUrl::ERROR
      }
    ].each do |example|
      context "with #{example[:name]} failure on entry request validation" do
        subject(:service_outcome) do
          described_class.call(params, Deposits::CallbackUrl::SUCCESS)
        end

        before do
          allow(approved_reply)
            .to receive(:validate!).and_raise(example[:error])
          allow(SafeCharge::DepositResponse)
            .to receive(:new).with(params).and_return(approved_reply)
        end

        it 'returns success' do
          expect(service_outcome).to eq example[:outcome]
        end
      end
    end

    [
      {
        name: 'approved message, correct context',
        passed_context: Deposits::CallbackUrl::SUCCESS,
        reply_stub: 'approved_reply',
        request_change: 'succeeded!',
        outcome: Deposits::CallbackUrl::SUCCESS
      },
      {
        name: 'approved message, incorrect context',
        passed_context: 'invalid_context',
        reply_stub: 'approved_reply',
        request_change: nil,
        outcome: Deposits::CallbackUrl::SOMETHING_WENT_WRONG
      },
      {
        name: 'pending message',
        passed_context: Deposits::CallbackUrl::PENDING,
        reply_stub: 'pending_reply',
        request_change: nil,
        outcome: Deposits::CallbackUrl::PENDING
      },
      {
        name: 'pending message, incorrect context',
        passed_context: 'invalid_context',
        reply_stub: 'pending_reply',
        request_change: nil,
        outcome: Deposits::CallbackUrl::SOMETHING_WENT_WRONG
      },
      {
        name: 'cancel flow',
        passed_context: Deposits::CallbackUrl::BACK,
        reply_stub: 'cancel_reply',
        request_change: 'failed!',
        outcome: Deposits::CallbackUrl::BACK
      },
      {
        name: 'default failure flow',
        passed_context: 'invalid_context',
        reply_stub: 'cancel_reply',
        request_change: 'failed!',
        outcome: Deposits::CallbackUrl::ERROR
      }
    ].each do |example|
      context "with valid reply, #{example[:name]}" do
        subject(:service_outcome) do
          described_class.call(params, example[:passed_context])
        end

        before do
          allow(SafeCharge::DepositResponse)
            .to receive(:new).with(params)
                             .and_return(send(example[:reply_stub]))
        end

        if example[:request_change]
          it "calls #{example[:request_change]} on entry request" do
            service_outcome
            expect(entry_request)
              .to have_received(example[:request_change]).once
          end
        end

        it "return #{example[:outcome]}" do
          expect(service_outcome).to eq example[:outcome]
        end
      end
    end
  end
end
