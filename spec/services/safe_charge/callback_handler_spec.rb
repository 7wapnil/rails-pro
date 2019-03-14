describe SafeCharge::CallbackHandler do
  let(:invalid_context) { Faker::Lorem.word }

  let(:entry_request) do
    create(:entry_request,
           kind: EntryRequest::DEPOSIT,
           status: EntryRequest::INITIAL)
  end
  let(:params) { { unique: :hash } }
  let(:transaction_id) { Faker::Number.number(10).to_s }
  let(:approved_response) do
    instance_double(
      SafeCharge::DepositResponse,
      'validate!' => true,
      'approved?' => true,
      'pending?' => false,
      'payment_method' => ::SafeCharge::PaymentMethods::CC_CARD,
      'entry_request' => entry_request,
      'transaction_id' => transaction_id
    )
  end

  let(:pending_response) do
    instance_double(
      SafeCharge::DepositResponse,
      'validate!' => true,
      'approved?' => false,
      'pending?' => true,
      'payment_method' => ::SafeCharge::PaymentMethods::CC_CARD,
      'entry_request' => entry_request,
      'transaction_id' => transaction_id
    )
  end

  let(:cancel_response) do
    instance_double(
      SafeCharge::DepositResponse,
      'validate!' => true,
      'approved?' => false,
      'pending?' => false,
      'payment_method' => ::SafeCharge::PaymentMethods::CC_CARD,
      'entry_request' => entry_request,
      'transaction_id' => transaction_id
    )
  end

  before do
    allow(entry_request).to receive('succeeded!')
    allow(entry_request).to receive('failed!')
    allow(entry_request).to receive('pending!')
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
          allow(approved_response)
            .to receive(:validate!).and_raise(example[:error])
          allow(SafeCharge::DepositResponse)
            .to receive(:new).with(params).and_return(approved_response)
        end

        it "returns #{example[:outcome]}" do
          expect(service_outcome).to eq example[:outcome]
        end
      end
    end

    shared_examples 'SafeCharge callback spec' do
      subject(:service_outcome) do
        described_class.call(params, passed_context)
      end

      before do
        allow(SafeCharge::DepositResponse)
          .to receive(:new)
          .with(params)
          .and_return(response)
      end

      context 'service call' do
        before { service_outcome }

        it 'sets entry status correctly' do
          expect(entry_request)
            .to have_received(entry_request_call)
            .exactly(expected_entry_request_call_count).times
        end

        it 'sets the external_id to whatever Response#transaction_id returns' do
          expect(entry_request.external_id).to eq(response.transaction_id)
        end
      end

      it 'returns expected outcome' do
        expect(service_outcome).to eq expected_outcome
      end
    end

    let(:invalid_context) { 'invalid_context' }

    context 'with approved message, correct context' do
      let(:passed_context) { Deposits::CallbackUrl::SUCCESS }
      let(:response) { approved_response }
      let(:entry_request_call) { 'succeeded!' }
      let(:expected_entry_request_call_count) { 1 }
      let(:expected_outcome) { Deposits::CallbackUrl::SUCCESS }

      it_behaves_like 'SafeCharge callback spec'
    end

    context 'with approved message, incorrect context' do
      let(:passed_context) { invalid_context }
      let(:response) { approved_response }
      let(:entry_request_call) { 'succeeded!' }
      let(:expected_entry_request_call_count) { 0 }
      let(:expected_outcome) { Deposits::CallbackUrl::SOMETHING_WENT_WRONG }

      it_behaves_like 'SafeCharge callback spec'
    end

    context 'with pending message' do
      let(:passed_context) { Deposits::CallbackUrl::PENDING }
      let(:response) { pending_response }
      let(:entry_request_call) { 'pending!' }
      let(:expected_entry_request_call_count) { 0 }
      let(:expected_outcome) { Deposits::CallbackUrl::PENDING }

      it_behaves_like 'SafeCharge callback spec'
    end

    context 'with pending message, incorrect context' do
      let(:passed_context) { invalid_context }
      let(:response) { pending_response }
      let(:entry_request_call) { 'pending!' }
      let(:expected_entry_request_call_count) { 0 }
      let(:expected_outcome) { Deposits::CallbackUrl::SOMETHING_WENT_WRONG }

      it_behaves_like 'SafeCharge callback spec'
    end

    context 'with cancel flow' do
      let(:passed_context) { Deposits::CallbackUrl::BACK }
      let(:response) { cancel_response }
      let(:entry_request_call) { 'failed!' }
      let(:expected_entry_request_call_count) { 1 }
      let(:expected_outcome) { Deposits::CallbackUrl::BACK }

      it_behaves_like 'SafeCharge callback spec'
    end

    context 'with default failure flow' do
      let(:passed_context) { invalid_context }
      let(:response) { cancel_response }
      let(:entry_request_call) { 'failed!' }
      let(:expected_entry_request_call_count) { 1 }
      let(:expected_outcome) { Deposits::CallbackUrl::ERROR }

      it_behaves_like 'SafeCharge callback spec'
    end
  end
end
